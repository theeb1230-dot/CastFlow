import 'dart:typed_data';

import 'package:castflow/features/streaming/data/transport/encoded_video_chunk_codec.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_reassembler.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits, encodes, decodes, and reassembles an H264 packet', () {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 4,
    );
    final EncodedVideoPacket packet = EncodedVideoPacket(
      data: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9]),
      presentationTimeUs: 123456,
      flags: 1,
    );

    final chunks = codec.split(packet: packet, sequence: 42);
    expect(chunks, hasLength(3));

    final EncodedVideoReassembler reassembler = EncodedVideoReassembler();
    EncodedVideoPacket? completed;

    for (final chunk in chunks.reversed) {
      completed =
          reassembler.add(codec.decode(codec.encode(chunk))) ?? completed;
    }

    expect(completed, isNotNull);
    expect(completed!.data, orderedEquals(packet.data));
    expect(completed.presentationTimeUs, packet.presentationTimeUs);
    expect(completed.flags, packet.flags);
  });

  test('rejects corrupted magic', () {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec();
    final bytes = Uint8List(28);
    expect(() => codec.decode(bytes), throwsA(isA<FormatException>()));
  });
}
