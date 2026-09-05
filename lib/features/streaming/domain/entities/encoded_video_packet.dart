import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class EncodedVideoPacket extends Equatable {
  const EncodedVideoPacket({
    required this.data,
    required this.presentationTimeUs,
    required this.flags,
  });

  final Uint8List data;
  final int presentationTimeUs;
  final int flags;

  @override
  List<Object> get props => <Object>[data, presentationTimeUs, flags];
}
