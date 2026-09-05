import 'package:castflow/features/session/domain/entities/connection_metrics.dart';
import 'package:castflow/features/streaming/domain/entities/streaming_profile.dart';
import 'package:castflow/features/streaming/domain/repositories/streaming_encoder_port.dart';
import 'package:castflow/features/streaming/domain/services/adaptive_bitrate_controller.dart';
import 'package:castflow/features/streaming/domain/services/adaptive_capture_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEncoder implements StreamingEncoderPort {
  final List<String> calls = <String>[];
  StreamingProfile? activeProfile;
  bool failNextStart = false;

  @override
  Future<void> start(StreamingProfile profile) async {
    calls.add('start:${profile.level.name}');
    if (failNextStart) {
      failNextStart = false;
      throw StateError('start failed');
    }
    activeProfile = profile;
  }

  @override
  Future<void> setBitrate(int bitrateBps) async {
    calls.add('bitrate:$bitrateBps');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    activeProfile = null;
  }

  @override
  Future<bool> isActive() async => activeProfile != null;
}

ConnectionMetrics healthyMetrics() {
  return const ConnectionMetrics(
    roundTripTimeMs: 20,
    jitterMs: 3,
    packetLossRate: 0.001,
    availableOutgoingBitrateBps: 20000000,
    bytesSent: 0,
    bytesReceived: 0,
    packetsLost: 0,
    packetsReceived: 1000,
  );
}

ConnectionMetrics degradedMetrics() {
  return const ConnectionMetrics(
    roundTripTimeMs: 180,
    jitterMs: 45,
    packetLossRate: 0.08,
    availableOutgoingBitrateBps: 1200000,
    bytesSent: 0,
    bytesReceived: 0,
    packetsLost: 80,
    packetsReceived: 920,
  );
}

void main() {
  test('starts encoder at the ABR initial profile', () async {
    final _FakeEncoder encoder = _FakeEncoder();
    final AdaptiveCaptureController controller = AdaptiveCaptureController(
      encoder: encoder,
    );

    await controller.start();

    expect(controller.appliedProfile, StreamingProfile.balanced);
    expect(encoder.calls, <String>['start:balanced']);
  });

  test('restarts encoder when ABR changes resolution or FPS', () async {
    final _FakeEncoder encoder = _FakeEncoder();
    final AdaptiveCaptureController controller = AdaptiveCaptureController(
      encoder: encoder,
      abr: AdaptiveBitrateController(
        initialProfile: StreamingProfile.high,
        degradeSampleThreshold: 1,
      ),
    );

    await controller.start();
    await controller.ingest(degradedMetrics());

    expect(controller.appliedProfile, StreamingProfile.balanced);
    expect(encoder.calls, <String>['start:high', 'stop', 'start:balanced']);
  });

  test('rolls back previous profile if encoder restart fails', () async {
    final _FakeEncoder encoder = _FakeEncoder();
    final AdaptiveCaptureController controller = AdaptiveCaptureController(
      encoder: encoder,
      abr: AdaptiveBitrateController(
        initialProfile: StreamingProfile.high,
        degradeSampleThreshold: 1,
      ),
    );

    await controller.start();
    encoder.failNextStart = true;

    expect(
      () => controller.ingest(degradedMetrics()),
      throwsA(isA<StateError>()),
    );
    expect(controller.appliedProfile, StreamingProfile.high);
    expect(encoder.calls, <String>[
      'start:high',
      'stop',
      'start:balanced',
      'start:high',
    ]);
  });

  test('upgrades only after ABR hysteresis threshold', () async {
    final _FakeEncoder encoder = _FakeEncoder();
    final AdaptiveCaptureController controller = AdaptiveCaptureController(
      encoder: encoder,
      abr: AdaptiveBitrateController(
        initialProfile: StreamingProfile.low,
        upgradeSampleThreshold: 2,
      ),
    );

    await controller.start();
    await controller.ingest(healthyMetrics());
    expect(controller.appliedProfile, StreamingProfile.low);

    await controller.ingest(healthyMetrics());
    expect(controller.appliedProfile, StreamingProfile.balanced);
    expect(encoder.calls, <String>['start:low', 'stop', 'start:balanced']);
  });
}
