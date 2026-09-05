import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/entities/screen_capture_config.dart';

class AndroidScreenCaptureService {
  AndroidScreenCaptureService({
    MethodChannel channel = const MethodChannel('castflow/screen_capture'),
  }) : _channel = channel;

  final MethodChannel _channel;
  MediaStream? _activeStream;

  MediaStream? get activeStream => _activeStream;

  Future<MediaStream> start(ScreenCaptureConfig config) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'AndroidScreenCaptureService is only available on Android.',
      );
    }
    if (_activeStream != null) {
      throw StateError('Screen capture is already active.');
    }

    await _channel.invokeMethod<void>('startForegroundService');

    try {
      final MediaStream stream = await navigator.mediaDevices.getDisplayMedia(
        config.toMediaConstraints(),
      );

      if (stream.getVideoTracks().isEmpty) {
        await _disposeStream(stream);
        throw StateError('Screen capture did not provide a video track.');
      }

      _activeStream = stream;
      return stream;
    } catch (_) {
      await _channel.invokeMethod<void>('stopForegroundService');
      rethrow;
    }
  }

  Future<void> stop() async {
    final MediaStream? stream = _activeStream;
    _activeStream = null;

    if (stream != null) {
      await _disposeStream(stream);
    }

    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('stopForegroundService');
    }
  }

  Future<void> _disposeStream(MediaStream stream) async {
    for (final MediaStreamTrack track in stream.getTracks()) {
      await track.stop();
    }
    await stream.dispose();
  }
}
