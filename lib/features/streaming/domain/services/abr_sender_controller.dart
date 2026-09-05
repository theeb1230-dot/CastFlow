import '../../../session/domain/entities/connection_metrics.dart';
import '../entities/streaming_profile.dart';
import '../repositories/video_sender_tuning_port.dart';
import 'adaptive_bitrate_controller.dart';

class AbrSenderController {
  AbrSenderController({
    required List<VideoSenderTuningPort> senders,
    AdaptiveBitrateController? controller,
  }) : _senders = List<VideoSenderTuningPort>.unmodifiable(senders),
       _controller = controller ?? AdaptiveBitrateController();

  final List<VideoSenderTuningPort> _senders;
  final AdaptiveBitrateController _controller;

  StreamingProfile get currentProfile => _controller.currentProfile;

  Future<StreamingProfile> ingest(ConnectionMetrics metrics) async {
    final StreamingProfile previous = _controller.currentProfile;
    final StreamingProfile selected = _controller.ingest(metrics);

    if (selected != previous) {
      await _apply(selected);
    }

    return selected;
  }

  Future<void> applyCurrentProfile() {
    return _apply(_controller.currentProfile);
  }

  Future<void> _apply(StreamingProfile profile) async {
    for (final VideoSenderTuningPort sender in _senders) {
      await sender.applyProfile(profile);
    }
  }
}
