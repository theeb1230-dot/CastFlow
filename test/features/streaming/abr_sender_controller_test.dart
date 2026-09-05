import 'package:castflow/features/session/domain/entities/connection_metrics.dart';
import 'package:castflow/features/streaming/domain/entities/streaming_profile.dart';
import 'package:castflow/features/streaming/domain/repositories/video_sender_tuning_port.dart';
import 'package:castflow/features/streaming/domain/services/abr_sender_controller.dart';
import 'package:castflow/features/streaming/domain/services/adaptive_bitrate_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSender implements VideoSenderTuningPort {
  final List<StreamingProfile> applied = <StreamingProfile>[];

  @override
  Future<void> applyProfile(StreamingProfile profile) async {
    applied.add(profile);
  }
}

ConnectionMetrics metrics({
  double rtt = 40,
  double jitter = 5,
  double loss = 0.005,
  double bitrate = 12000000,
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
  test('applies current profile to all outbound video senders', () async {
    final _FakeSender first = _FakeSender();
    final _FakeSender second = _FakeSender();
    final AbrSenderController controller = AbrSenderController(
      senders: <VideoSenderTuningPort>[first, second],
    );

    await controller.applyCurrentProfile();

    expect(first.applied, <StreamingProfile>[StreamingProfile.balanced]);
    expect(second.applied, <StreamingProfile>[StreamingProfile.balanced]);
  });

  test('applies a profile only when ABR actually changes level', () async {
    final _FakeSender sender = _FakeSender();
    final AbrSenderController controller = AbrSenderController(
      senders: <VideoSenderTuningPort>[sender],
      controller: AdaptiveBitrateController(
        initialProfile: StreamingProfile.high,
        degradeSampleThreshold: 2,
      ),
    );

    await controller.ingest(metrics(loss: 0.1, bitrate: 1000000));
    expect(sender.applied, isEmpty);

    final StreamingProfile selected = await controller.ingest(
      metrics(loss: 0.1, bitrate: 1000000),
    );

    expect(selected, StreamingProfile.balanced);
    expect(sender.applied, <StreamingProfile>[StreamingProfile.balanced]);
  });
}
