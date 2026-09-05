import 'dart:typed_data';

import '../../domain/entities/encoded_video_chunk.dart';
import '../../domain/entities/encoded_video_packet.dart';

class EncodedVideoChunkCodec {
  const EncodedVideoChunkCodec({this.maxPayloadBytes = 16 * 1024});

  static const int _magic = 0x43464832;
  static const int _version = 1;
  static const int _headerBytes = 28;

  final int maxPayloadBytes;

  List<EncodedVideoChunk> split({
    required EncodedVideoPacket packet,
    required int sequence,
  }) {
    if (maxPayloadBytes <= 0) {
      throw StateError('maxPayloadBytes must be positive.');
    }

    final int count = (packet.data.length / maxPayloadBytes).ceil().clamp(
      1,
      0xFFFF,
    );

    final List<EncodedVideoChunk> chunks = <EncodedVideoChunk>[];
    for (int index = 0; index < count; index++) {
      final int start = index * maxPayloadBytes;
      final int end = (start + maxPayloadBytes).clamp(0, packet.data.length);
      chunks.add(
        EncodedVideoChunk(
          sequence: sequence,
          chunkIndex: index,
          chunkCount: count,
          presentationTimeUs: packet.presentationTimeUs,
          flags: packet.flags,
          payload: Uint8List.sublistView(packet.data, start, end),
        ),
      );
    }
    return chunks;
  }

  Uint8List encode(EncodedVideoChunk chunk) {
    if (chunk.chunkIndex < 0 ||
        chunk.chunkIndex >= chunk.chunkCount ||
        chunk.chunkCount <= 0 ||
        chunk.chunkCount > 0xFFFF) {
      throw const FormatException('Invalid encoded video chunk indices.');
    }

    final Uint8List bytes = Uint8List(_headerBytes + chunk.payload.length);
    final ByteData header = ByteData.sublistView(bytes, 0, _headerBytes);

    header.setUint32(0, _magic);
    header.setUint8(4, _version);
    header.setUint8(5, 0);
    header.setUint16(6, _headerBytes);
    header.setUint32(8, chunk.sequence);
    header.setUint16(12, chunk.chunkIndex);
    header.setUint16(14, chunk.chunkCount);
    header.setInt64(16, chunk.presentationTimeUs);
    header.setUint32(24, chunk.flags);

    bytes.setRange(_headerBytes, bytes.length, chunk.payload);
    return bytes;
  }

  EncodedVideoChunk decode(Uint8List bytes) {
    if (bytes.length < _headerBytes) {
      throw const FormatException('Encoded video chunk is too small.');
    }

    final ByteData header = ByteData.sublistView(bytes, 0, _headerBytes);
    if (header.getUint32(0) != _magic) {
      throw const FormatException('Encoded video chunk magic mismatch.');
    }
    if (header.getUint8(4) != _version) {
      throw const FormatException('Encoded video chunk version mismatch.');
    }

    final int headerBytes = header.getUint16(6);
    if (headerBytes != _headerBytes || bytes.length < headerBytes) {
      throw const FormatException('Encoded video chunk header is invalid.');
    }

    final int sequence = header.getUint32(8);
    final int chunkIndex = header.getUint16(12);
    final int chunkCount = header.getUint16(14);
    if (chunkCount <= 0 || chunkIndex >= chunkCount) {
      throw const FormatException('Encoded video chunk indices are invalid.');
    }

    return EncodedVideoChunk(
      sequence: sequence,
      chunkIndex: chunkIndex,
      chunkCount: chunkCount,
      presentationTimeUs: header.getInt64(16),
      flags: header.getUint32(24),
      payload: Uint8List.sublistView(bytes, headerBytes),
    );
  }
}
