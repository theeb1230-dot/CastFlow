import 'dart:io';
import 'package:flutter/services.dart';

import '../../domain/entities/encoded_video_packet.dart';
import '../../domain/repositories/encoded_video_renderer_port.dart';

class AndroidTvH264Renderer implements EncodedVideoRendererPort {
  AndroidTvH264Renderer({
    MethodChannel channel = const MethodChannel('castflow/hardware_decoder'),
  }) : _channel = channel;

  final MethodChannel _channel;
  int? _textureId;

  @override
  int? get textureId => _textureId;

  @override
  Future<int> initialize({required int width, required int height}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'AndroidTvH264Renderer is only available on Android.',
      );
    }
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be positive.');
    }

    final int? textureId = await _channel.invokeMethod<int>(
      'initialize',
      <String, Object>{'width': width, 'height': height},
    );
    if (textureId == null) {
      throw StateError('Android decoder did not return a texture id.');
    }
    _textureId = textureId;
    return textureId;
  }

  @override
  Future<void> push(EncodedVideoPacket packet) async {
    if (!Platform.isAndroid) {
      return;
    }
    if (_textureId == null) {
      throw StateError('Renderer must be initialized before pushing packets.');
    }

    await _channel.invokeMethod<void>('push', <String, Object>{
      'data': Uint8List.fromList(packet.data),
      'presentationTimeUs': packet.presentationTimeUs,
      'flags': packet.flags,
    });
  }

  @override
  Future<void> dispose() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('dispose');
    }
    _textureId = null;
  }
}
