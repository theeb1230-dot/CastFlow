import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import '../../domain/entities/encoded_video_packet.dart';
import '../../domain/entities/streaming_profile.dart';

class AndroidHardwareEncoder {
  AndroidHardwareEncoder({
    MethodChannel methodChannel = const MethodChannel(
      'castflow/hardware_encoder',
    ),
    EventChannel eventChannel = const EventChannel(
      'castflow/hardware_encoder/events',
    ),
  }) : _methodChannel = methodChannel,
       _eventChannel = eventChannel;

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<EncodedVideoPacket>? _packetStream;

  Stream<EncodedVideoPacket> get packets {
    return _packetStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((dynamic event) {
          return event is Map && event['data'] is Uint8List;
        })
        .map((dynamic event) {
          final Map<Object?, Object?> map = event as Map<Object?, Object?>;
          return EncodedVideoPacket(
            data: map['data']! as Uint8List,
            presentationTimeUs: map['presentationTimeUs']! as int,
            flags: map['flags']! as int,
          );
        });
  }

  Future<void> start(StreamingProfile profile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'AndroidHardwareEncoder is only available on Android.',
      );
    }

    await _methodChannel.invokeMethod<void>('start', <String, Object>{
      'width': profile.width,
      'height': profile.height,
      'fps': profile.framesPerSecond,
      'bitrate': profile.targetBitrateBps,
    });
  }

  Future<void> setBitrate(int bitrateBps) async {
    if (!Platform.isAndroid) {
      return;
    }
    if (bitrateBps <= 0) {
      throw ArgumentError.value(bitrateBps, 'bitrateBps', 'Must be positive.');
    }

    await _methodChannel.invokeMethod<void>('setBitrate', <String, Object>{
      'bitrate': bitrateBps,
    });
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _methodChannel.invokeMethod<void>('stop');
  }

  Future<bool> isActive() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return await _methodChannel.invokeMethod<bool>('isActive') ?? false;
  }
}
