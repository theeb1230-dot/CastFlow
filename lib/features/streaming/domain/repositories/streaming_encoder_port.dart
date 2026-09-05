import '../entities/streaming_profile.dart';

abstract interface class StreamingEncoderPort {
  Future<void> start(StreamingProfile profile);

  Future<void> setBitrate(int bitrateBps);

  Future<void> stop();

  Future<bool> isActive();
}
