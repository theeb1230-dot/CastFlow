import 'dart:typed_data';

import '../../domain/entities/encoded_video_chunk.dart';
import '../../domain/entities/encoded_video_packet.dart';

class EncodedVideoReassembler {
  final Map<int, _PendingPacket> _pending = <int, _PendingPacket>{};

  EncodedVideoPacket? add(EncodedVideoChunk chunk) {
    final _PendingPacket pending = _pending.putIfAbsent(
      chunk.sequence,
      () => _PendingPacket.fromChunk(chunk),
    );

    if (!pending.matches(chunk)) {
      _pending.remove(chunk.sequence);
      throw const FormatException('Chunk metadata changed within a packet.');
    }

    pending.add(chunk);

    if (!pending.isComplete) {
      return null;
    }

    _pending.remove(chunk.sequence);
    return pending.toPacket();
  }

  void clear() {
    _pending.clear();
  }
}

class _PendingPacket {
  _PendingPacket({
    required this.presentationTimeUs,
    required this.flags,
    required this.chunkCount,
  }) : chunks = List<Uint8List?>.filled(chunkCount, null);

  factory _PendingPacket.fromChunk(EncodedVideoChunk chunk) {
    return _PendingPacket(
      presentationTimeUs: chunk.presentationTimeUs,
      flags: chunk.flags,
      chunkCount: chunk.chunkCount,
    );
  }

  final int presentationTimeUs;
  final int flags;
  final int chunkCount;
  final List<Uint8List?> chunks;

  bool matches(EncodedVideoChunk chunk) {
    return chunk.presentationTimeUs == presentationTimeUs &&
        chunk.flags == flags &&
        chunk.chunkCount == chunkCount;
  }

  void add(EncodedVideoChunk chunk) {
    chunks[chunk.chunkIndex] = chunk.payload;
  }

  bool get isComplete => chunks.every((Uint8List? chunk) => chunk != null);

  EncodedVideoPacket toPacket() {
    final int totalLength = chunks.fold<int>(
      0,
      (int total, Uint8List? chunk) => total + chunk!.length,
    );
    final Uint8List data = Uint8List(totalLength);

    int offset = 0;
    for (final Uint8List? chunk in chunks) {
      final Uint8List bytes = chunk!;
      data.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }

    return EncodedVideoPacket(
      data: data,
      presentationTimeUs: presentationTimeUs,
      flags: flags,
    );
  }
}
