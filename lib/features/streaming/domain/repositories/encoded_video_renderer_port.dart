import '../entities/encoded_video_packet.dart';

abstract interface class EncodedVideoRendererPort {
  int? get textureId;

  Future<int> initialize({required int width, required int height});

  /// Returns true only when this push produced a decoder output frame that
  /// was released for rendering to the output surface.
  Future<bool> push(EncodedVideoPacket packet);

  Future<void> dispose();
}
