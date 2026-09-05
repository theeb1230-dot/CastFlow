import '../entities/streaming_profile.dart';

abstract interface class VideoSenderTuningPort {
  Future<void> applyProfile(StreamingProfile profile);
}
