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

  int? get textureId => _renderer.textureId;

  Future<int> start({
    required Stream<EncodedVideoPacket> packets,
    required int width,
    required int height,
  }) async {
    if (_disposed) {
      throw StateError('Receiver pipeline is disposed.');
    }
    if (_subscription != null) {
      throw StateError('Receiver pipeline is already active.');
    }

    final int textureId = await _renderer.initialize(
      width: width,
      height: height,
    );

    _subscription = packets.listen(
      _enqueue,
      onError: (_) {},
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
      await _renderer.dispose();
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stop();
  }

  void _enqueue(EncodedVideoPacket packet) {
    _tail = _tail.then((_) => _renderer.push(packet));
  }
}
