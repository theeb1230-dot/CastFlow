import 'dart:async';

import '../../domain/entities/encoded_video_packet.dart';
import '../../domain/repositories/encoded_video_renderer_port.dart';

class AndroidTvReceiverPipeline {
  AndroidTvReceiverPipeline({required EncodedVideoRendererPort renderer})
    : _renderer = renderer;

  final EncodedVideoRendererPort _renderer;

  StreamSubscription<EncodedVideoPacket>? _subscription;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;
  bool _firstFrameRendered = false;

  int? get textureId => _renderer.textureId;

  Future<int> start({
    required Stream<EncodedVideoPacket> packets,
    required int width,
    required int height,
    void Function()? onFirstFrameRendered,
    void Function(Object error, StackTrace stackTrace)? onRenderError,
  }) async {
    if (_disposed) throw StateError('Receiver pipeline is disposed.');
    if (_subscription != null) {
      throw StateError('Receiver pipeline is already active.');
    }

    final int textureId = await _renderer.initialize(
      width: width,
      height: height,
    );
    _firstFrameRendered = false;
    _subscription = packets.listen(
      (EncodedVideoPacket packet) => _enqueue(
        packet,
        onFirstFrameRendered: onFirstFrameRendered,
        onRenderError: onRenderError,
      ),
      onError: (Object error, StackTrace stackTrace) =>
          onRenderError?.call(error, stackTrace),
      cancelOnError: false,
    );
    return textureId;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _tail;
    } finally {
      _tail = Future<void>.value();
      _firstFrameRendered = false;
      await _renderer.dispose();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
  }

  void _enqueue(
    EncodedVideoPacket packet, {
    void Function()? onFirstFrameRendered,
    void Function(Object error, StackTrace stackTrace)? onRenderError,
  }) {
    _tail = _tail.then((_) async {
      try {
        await _renderer.push(packet);
        final bool candidateFrame = (packet.flags & 2) == 0;
        if (candidateFrame && !_firstFrameRendered) {
          _firstFrameRendered = true;
          onFirstFrameRendered?.call();
        }
      } catch (error, stackTrace) {
        onRenderError?.call(error, stackTrace);
      }
    });
  }
}
