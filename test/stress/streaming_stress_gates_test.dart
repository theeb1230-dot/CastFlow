import 'dart:async';
import 'dart:typed_data';

import 'package:castflow/features/session/domain/entities/connection_metrics.dart';
import 'package:castflow/features/session/domain/repositories/session_recovery_port.dart';
import 'package:castflow/features/session/domain/services/session_recovery_controller.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_chunk_codec.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_reassembler.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:castflow/features/streaming/domain/entities/streaming_profile.dart';
import 'package:castflow/features/streaming/domain/services/adaptive_bitrate_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecoveryPort implements SessionRecoveryPort {
  int restartCalls = 0;
  Completer<void>? gate;

  @override
  Future<void> restartTransport() async {
    restartCalls += 1;
    final Completer<void>? current = gate;
    if (current != null) {
      await current.future;
    }
  }
}

ConnectionMetrics _healthy() {
  return const ConnectionMetrics(
    roundTripTimeMs: 18,
    jitterMs: 2,
    packetLossRate: 0.001,
    availableOutgoingBitrateBps: 25000000,
    bytesSent: 0,
    bytesReceived: 0,
    packetsLost: 0,
    packetsReceived: 1000,
  );
}

ConnectionMetrics _degraded() {
  return const ConnectionMetrics(
    roundTripTimeMs: 220,
    jitterMs: 60,
    packetLossRate: 0.12,
    availableOutgoingBitrateBps: 700000,
    bytesSent: 0,
    bytesReceived: 0,
    packetsLost: 120,
    packetsReceived: 880,
  );
}

void main() {
  test('reassembly remains bounded under incomplete-frame flood', () {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 32,
    );
    final EncodedVideoReassembler reassembler = EncodedVideoReassembler(
      maxPendingPackets: 8,
    );

    for (int sequence = 0; sequence < 10000; sequence++) {
      final EncodedVideoPacket packet = EncodedVideoPacket(
        data: Uint8List(64),
        presentationTimeUs: sequence * 33333,
        flags: 0,
      );
      final chunks = codec.split(packet: packet, sequence: sequence);
      reassembler.add(chunks.first);
      expect(reassembler.pendingPacketCount, lessThanOrEqualTo(8));
    }

    expect(reassembler.pendingPacketCount, 8);
    reassembler.clear();
    expect(reassembler.pendingPacketCount, 0);
  });

  test('recovery storm coalesces concurrent transport-loss signals', () async {
    final _RecoveryPort port = _RecoveryPort();
    port.gate = Completer<void>();
    final SessionRecoveryController controller = SessionRecoveryController(
      port: port,
      maxAttempts: 3,
      sleeper: (_) async {},
    );

    final List<Future<SessionRecoveryState>> calls =
        List<Future<SessionRecoveryState>>.generate(
          1000,
          (_) => controller.onTransportLost(),
        );

    await Future<void>.delayed(Duration.zero);
    expect(port.restartCalls, 1);

    port.gate!.complete();
    await Future.wait(calls);

    expect(port.restartCalls, 1);
    expect(controller.attempts, 1);

    controller.onTransportRecovered();
    expect(controller.state, SessionRecoveryState.connected);
    expect(controller.attempts, 0);
  });

  test(
    'ABR survives sustained alternating network pressure without invalid state',
    () {
      final AdaptiveBitrateController controller = AdaptiveBitrateController(
        initialProfile: StreamingProfile.balanced,
        degradeSampleThreshold: 2,
        upgradeSampleThreshold: 5,
      );

      for (int i = 0; i < 10000; i++) {
        final StreamingProfile profile = controller.ingest(
          i.isEven ? _degraded() : _healthy(),
        );
        expect(
          profile.level,
          isIn(<StreamingProfileLevel>[
            StreamingProfileLevel.low,
            StreamingProfileLevel.balanced,
            StreamingProfileLevel.high,
          ]),
        );
        expect(profile.targetBitrateBps, greaterThan(0));
        expect(profile.framesPerSecond, greaterThan(0));
        expect(profile.width, greaterThan(0));
        expect(profile.height, greaterThan(0));
      }
    },
  );

  test('stress gates complete within generous CI budget', () {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 1200,
    );
    final Stopwatch stopwatch = Stopwatch()..start();

    for (int sequence = 0; sequence < 5000; sequence++) {
      final EncodedVideoPacket packet = EncodedVideoPacket(
        data: Uint8List(8192),
        presentationTimeUs: sequence * 16667,
        flags: sequence % 60 == 0 ? 1 : 0,
      );
      final EncodedVideoReassembler reassembler = EncodedVideoReassembler();
      EncodedVideoPacket? completed;
      for (final chunk in codec.split(packet: packet, sequence: sequence)) {
        completed = reassembler.add(codec.decode(codec.encode(chunk)));
      }
      expect(completed, isNotNull);
      expect(completed!.data.length, packet.data.length);
    }

    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 20)),
      reason: 'Encoded-video stress gate exceeded the CI performance budget.',
    );
  });
}
