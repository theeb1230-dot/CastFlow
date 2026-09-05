import 'package:castflow/features/session/domain/entities/connection_metrics.dart';
import 'package:castflow/features/streaming/domain/entities/streaming_profile.dart';
import 'package:castflow/features/streaming/domain/services/adaptive_bitrate_controller.dart';
import 'package:flutter_test/flutter_test.dart';

ConnectionMetrics metrics({
  double? rtt = 40,
  double? jitter = 5,
  double loss = 0.005,
  double? bitrate = 10000000,
}) {
  return ConnectionMetrics(
    roundTripTimeMs: rtt,
    jitterMs: jitter,
    packetLossRate: loss,
    availableOutgoingBitrateBps: bitrate,
    bytesSent: 0,
    bytesReceived: 0,
    packetsLost: 0,
    packetsReceived: 1000,
  );
}

void main() {
  test('does not downgrade on a single degraded sample', () {
    final AdaptiveBitrateController controller = AdaptiveBitrateController();

    final StreamingProfile profile = controller.ingest(
      metrics(rtt: 160, jitter: 45, loss: 0.08, bitrate: 2000000),
    );

    expect(profile, StreamingProfile.balanced);
  });

  test('downgrades after consecutive degraded samples', () {
    final AdaptiveBitrateController controller = AdaptiveBitrateController();

    controller.ingest(
      metrics(rtt: 160, jitter: 45, loss: 0.08, bitrate: 2000000),
    );
    final StreamingProfile profile = controller.ingest(
      metrics(rtt: 150, jitter: 40, loss: 0.07, bitrate: 2200000),
    );

    expect(profile, StreamingProfile.low);
  });

  test('upgrades only after sustained healthy headroom', () {
    final AdaptiveBitrateController controller = AdaptiveBitrateController(
      initialProfile: StreamingProfile.low,
    );

    StreamingProfile profile = controller.currentProfile;
    for (int index = 0; index < 4; index += 1) {
      profile = controller.ingest(metrics(bitrate: 9000000));
      expect(profile, StreamingProfile.low);
    }

    profile = controller.ingest(metrics(bitrate: 9000000));

    expect(profile, StreamingProfile.balanced);
  });

  test('does not upgrade without enough bitrate headroom', () {
    final AdaptiveBitrateController controller = AdaptiveBitrateController(
      initialProfile: StreamingProfile.low,
    );

    for (int index = 0; index < 8; index += 1) {
      controller.ingest(metrics(bitrate: 4000000));
    }

    expect(controller.currentProfile, StreamingProfile.low);
  });

  test('steps down one profile at a time', () {
    final AdaptiveBitrateController controller = AdaptiveBitrateController(
      initialProfile: StreamingProfile.high,
    );

    controller.ingest(metrics(loss: 0.08, bitrate: 3000000));
    controller.ingest(metrics(loss: 0.08, bitrate: 3000000));

    expect(controller.currentProfile, StreamingProfile.balanced);
  });
}
