import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../domain/entities/encoded_video_packet.dart';

class EncodedVideoPacketEventDecoder {
  const EncodedVideoPacketEventDecoder();

  EncodedVideoPacket decode(dynamic event) {
    if (event is! Map) {
      throw const FormatException('Encoded video event must be a map.');
    }

    final dynamic data = event['data'];
    final dynamic presentationTimeUs = event['presentationTimeUs'];
    final dynamic flags = event['flags'];

    if (data is! Uint8List || presentationTimeUs is! int || flags is! int) {
      throw const FormatException('Encoded video event fields are invalid.');
    }

    return EncodedVideoPacket(
      data: data,
      presentationTimeUs: presentationTimeUs,
      flags: flags,
    );
  }
}

class IosReplayKitEncodedSource {
  IosReplayKitEncodedSource({
    EventChannel eventChannel = const EventChannel(
      'castflow/replaykit_encoded/events',
    ),
    EncodedVideoPacketEventDecoder decoder =
        const EncodedVideoPacketEventDecoder(),
  }) : _eventChannel = eventChannel,
       _decoder = decoder;

  final EventChannel _eventChannel;
  final EncodedVideoPacketEventDecoder _decoder;

  Stream<EncodedVideoPacket>? _packets;

  Stream<EncodedVideoPacket> get packets {
    return _packets ??= _eventChannel.receiveBroadcastStream().map(
      _decoder.decode,
    );
  }
}
