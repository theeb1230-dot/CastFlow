import 'package:castflow/features/session/domain/entities/connection_metrics.dart';
import 'package:castflow/features/session/domain/entities/streaming_profile.dart';
import 'package:castflow/features/session/domain/services/abr_controller.dart';
import 'package:castflow/features/session/domain/services/adaptive_bitrate_policy.dart';
import 'package:flutter_test/flutter_test.dart';

ConnectionMetrics metrics({
  double? rtt = 40,
  double? jitter = 5,
  double loss = 0.005,
  double? bitrate = 12000000,
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
  const AdaptiveBitratePolicy policy = AdaptiveBitratePolicy();

  test('selects ultra profile for healthy high-capacity connection', () {
    expect(policy.selectProfile(metrics()), StreamingProfile.ultra);
  });

  test('selects low profile for severe packet loss', () {
    expect(
      policy.selectProfile(metrics(loss: 0.1)),
      StreamingProfile.low,
    );
  });

  test('selects balanced profile for moderate RTT', () {
    expect(
      policy.selectProfile(metrics(rtt: 130)),
      StreamingProfile.balanced,
    );
  });

  test('downgrades faster than it upgrades to avoid oscillation', () {
    final AbrController controller = AbrController(
      requiredStableSamples: 3,
      requiredDegradedSamples: 2,
    );

    expect(controller.current, StreamingProfile.balanced);

    controller.update(metrics());
    controller.update(metrics());
    expect(controller.current, StreamingProfile.balanced);

    controller.update(metrics());
    expect(controller.current, StreamingProfile.ultra);

    controller.update(metrics(loss: 0.1));
    expect(controller.current, StreamingProfile.ultra);

    controller.update(metrics(loss: 0.1));
    expect(controller.current, StreamingProfile.low);
  });

  test('resets hysteresis state predictably', () {
    final AbrController controller = AbrController();
    controller.update(metrics());
    controller.reset(StreamingProfile.high);

    expect(controller.current, StreamingProfile.high);
  });
}
