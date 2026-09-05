import '../entities/encoded_video_packet.dart';

abstract interface class EncodedVideoRendererPort {
  int? get textureId;

  Future<int> initialize({required int width, required int height});

  Future<void> push(EncodedVideoPacket packet);

  Future<void> dispose();
}
