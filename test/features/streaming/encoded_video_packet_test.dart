import 'dart:typed_data';

import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encoded packet preserves payload and timing metadata', () {
    final Uint8List bytes = Uint8List.fromList(<int>[0, 0, 0, 1, 103]);

    final EncodedVideoPacket packet = EncodedVideoPacket(
      data: bytes,
      presentationTimeUs: 123456,
      flags: 1,
    );

    expect(packet.data, bytes);
    expect(packet.presentationTimeUs, 123456);
    expect(packet.flags, 1);
  });
}
