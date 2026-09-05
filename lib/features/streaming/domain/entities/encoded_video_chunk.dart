import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class EncodedVideoChunk extends Equatable {
  const EncodedVideoChunk({
    required this.sequence,
    required this.chunkIndex,
    required this.chunkCount,
    required this.presentationTimeUs,
    required this.flags,
    required this.payload,
  });

  final int sequence;
  final int chunkIndex;
  final int chunkCount;
  final int presentationTimeUs;
  final int flags;
  final Uint8List payload;

  bool get isLastChunk => chunkIndex == chunkCount - 1;

  @override
  List<Object> get props => <Object>[
    sequence,
    chunkIndex,
    chunkCount,
    presentationTimeUs,
    flags,
    payload,
  ];
}
