import 'dart:typed_data';

import 'package:castflow/features/streaming/data/transport/encoded_video_chunk_codec.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_reassembler.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encoded frame chunking stays within performance smoke budget', () {
    const int frameCount = 1000;
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 16 * 1024,
    );
    final EncodedVideoReassembler reassembler = EncodedVideoReassembler(
      maxPendingPackets: 8,
    );
    final Uint8List frameBytes = Uint8List(32 * 1024);
    for (int index = 0; index < frameBytes.length; index++) {
      frameBytes[index] = index & 0xFF;
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    int completed = 0;

    for (int sequence = 0; sequence < frameCount; sequence++) {
      final EncodedVideoPacket packet = EncodedVideoPacket(
        data: frameBytes,
        presentationTimeUs: sequence * 33333,
        flags: sequence % 30 == 0 ? 1 : 0,
      );

      final chunks = codec.split(packet: packet, sequence: sequence);
      for (final chunk in chunks) {
        final restored = reassembler.add(codec.decode(codec.encode(chunk)));
        if (restored != null) {
          completed += 1;
          expect(restored.data.length, frameBytes.length);
        }
      }
    }

    stopwatch.stop();

    expect(completed, frameCount);
    expect(reassembler.pendingPacketCount, 0);
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 15)),
      reason:
          'Chunk framing exceeded the broad CI smoke budget and may contain '
          'a major performance regression.',
    );
  });
}
