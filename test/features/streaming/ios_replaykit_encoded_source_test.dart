import 'dart:typed_data';

import 'package:castflow/features/streaming/data/encoder/ios_replaykit_encoded_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const EncodedVideoPacketEventDecoder decoder =
      EncodedVideoPacketEventDecoder();

  test('decodes ReplayKit encoded packet event', () {
    final packet = decoder.decode(<String, Object>{
      'data': Uint8List.fromList(<int>[0, 0, 0, 1, 0x65, 1, 2, 3]),
      'presentationTimeUs': 123456,
      'flags': 1,
    });

    expect(packet.presentationTimeUs, 123456);
    expect(packet.flags, 1);
    expect(packet.data, orderedEquals(<int>[0, 0, 0, 1, 0x65, 1, 2, 3]));
  });

  test('rejects malformed ReplayKit encoded packet event', () {
    expect(
      () => decoder.decode(<String, Object>{
        'data': 'not-bytes',
        'presentationTimeUs': 1,
        'flags': 0,
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => decoder.decode('invalid'),
      throwsA(isA<FormatException>()),
    );
  });
}
