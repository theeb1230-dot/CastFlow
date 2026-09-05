import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:castflow/features/session/data/signaling/local_signaling_client.dart';
import 'package:castflow/features/session/data/signaling/local_signaling_server.dart';
import 'package:castflow/features/session/domain/entities/signaling_message.dart';
import 'package:castflow/features/session/domain/repositories/session_recovery_port.dart';
import 'package:castflow/features/session/domain/services/session_recovery_controller.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_chunk_codec.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_reassembler.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:flutter_test/flutter_test.dart';

class _StressRecoveryPort implements SessionRecoveryPort {
  int restartCalls = 0;

  @override
  Future<void> restartTransport() async {
    restartCalls += 1;
  }
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!predicate()) {
    if (stopwatch.elapsed >= timeout) {
      throw TimeoutException('Condition was not reached before timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('reassembly memory stays bounded under incomplete frame stress', () {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 1,
    );
    final EncodedVideoReassembler reassembler = EncodedVideoReassembler(
      maxPendingPackets: 8,
    );

    for (int sequence = 0; sequence < 5000; sequence++) {
      final EncodedVideoPacket packet = EncodedVideoPacket(
        data: Uint8List.fromList(<int>[
          sequence & 0xFF,
          (sequence >> 8) & 0xFF,
        ]),
        presentationTimeUs: sequence * 33333,
        flags: 0,
      );
      final chunks = codec.split(packet: packet, sequence: sequence);

      expect(chunks, hasLength(2));
      expect(reassembler.add(chunks.first), isNull);
      expect(reassembler.pendingPacketCount, lessThanOrEqualTo(8));
    }

    expect(reassembler.pendingPacketCount, 8);
    reassembler.clear();
    expect(reassembler.pendingPacketCount, 0);
  });

  test(
    'recovery attempts do not accumulate across 1000 recovered sessions',
    () async {
      final _StressRecoveryPort port = _StressRecoveryPort();
      final SessionRecoveryController controller = SessionRecoveryController(
        port: port,
        maxAttempts: 3,
        sleeper: (_) async {},
      );

      for (int cycle = 0; cycle < 1000; cycle++) {
        final SessionRecoveryState state = await controller.onTransportLost();
        expect(state, SessionRecoveryState.recovering);
        controller.onTransportRecovered();
        expect(controller.state, SessionRecoveryState.connected);
        expect(controller.attempts, 0);
      }

      expect(port.restartCalls, 1000);
    },
  );

  test(
    'authenticated signaling sockets are released across reconnect cycles',
    () async {
      final LocalSignalingServer server = LocalSignalingServer(
        sessionId: 'stress-session',
        token: 'stress-token',
        address: InternetAddress.loopbackIPv4,
        maxClients: 4,
      );
      await server.start();

      try {
        for (int cycle = 0; cycle < 50; cycle++) {
          final LocalSignalingClient client = LocalSignalingClient(
            host: InternetAddress.loopbackIPv4.address,
            port: server.boundPort,
            sessionId: 'stress-session',
            token: 'stress-token',
          );

          await client.connectAuthenticated();

          expect(server.connectedClientCount, 1);
          expect(server.authenticatedClientCount, 1);

          final Future<SignalingMessage> received = server.messages
              .firstWhere(
                (SignalingMessage message) =>
                    message.type == SignalingMessageType.offer &&
                    message.payload['cycle'] == cycle,
              )
              .timeout(const Duration(seconds: 2));

          await client.send(SignalingMessageType.offer, <String, Object?>{
            'cycle': cycle,
          });
          await received;
          await client.dispose();

          await _waitUntil(
            () =>
                server.connectedClientCount == 0 &&
                server.authenticatedClientCount == 0,
          );
        }

        expect(server.connectedClientCount, 0);
        expect(server.authenticatedClientCount, 0);
      } finally {
        await server.dispose();
      }
    },
  );

  test('signaling server enforces its concurrent client bound', () async {
    final LocalSignalingServer server = LocalSignalingServer(
      sessionId: 'bound-session',
      token: 'bound-token',
      address: InternetAddress.loopbackIPv4,
      maxClients: 3,
    );
    await server.start();

    final List<Socket> sockets = <Socket>[];
    try {
      for (int index = 0; index < 12; index++) {
        sockets.add(
          await Socket.connect(InternetAddress.loopbackIPv4, server.boundPort),
        );
      }

      await _waitUntil(() => server.connectedClientCount == 3);
      expect(server.connectedClientCount, 3);
      expect(server.authenticatedClientCount, 0);
    } finally {
      for (final Socket socket in sockets) {
        socket.destroy();
      }
      await server.dispose();
    }
  });
}
