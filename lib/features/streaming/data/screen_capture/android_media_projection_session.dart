import 'dart:io';

import 'package:flutter/services.dart';

class AndroidMediaProjectionSession {
  AndroidMediaProjectionSession({
    MethodChannel channel = const MethodChannel('castflow/media_projection'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> requestAndStart() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'AndroidMediaProjectionSession is only available on Android.',
      );
    }

    await _channel.invokeMethod<void>('requestAndStart');
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('stop');
  }

  Future<bool> isActive() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return await _channel.invokeMethod<bool>('isActive') ?? false;
  }

  Future<int> sdkInt() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'AndroidMediaProjectionSession is only available on Android.',
      );
    }
    return await _channel.invokeMethod<int>('getSdkInt') ?? 0;
  }
}
