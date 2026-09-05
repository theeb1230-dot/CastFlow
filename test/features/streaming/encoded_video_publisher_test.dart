import 'dart:async';
import 'dart:typed_data';

import 'package:castflow/features/streaming/data/transport/encoded_video_chunk_codec.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_publisher.dart';
import 'package:castflow/features/streaming/data/transport/encoded_video_reassembler.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:castflow/features/streaming/domain/repositories/binary_video_transport.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTransport implements BinaryVideoTransport {
  final List<Uint8List> sent = <Uint8List>[];
  final StreamController<Uint8List> controller =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get messages => controller.stream;

  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(bytes);
  }

  @override
  Future<void> close() async {
    await controller.close();
  }
}

void main() {
  test('publisher preserves encoded frame through chunk framing', () async {
    const EncodedVideoChunkCodec codec = EncodedVideoChunkCodec(
      maxPayloadBytes: 3,
    );
    final _MemoryTransport transport = _MemoryTransport();
    final EncodedVideoPublisher publisher = EncodedVideoPublisher(
      transport: transport,
      codec: codec,
    );
    final StreamController<EncodedVideoPacket> source =
        StreamController<EncodedVideoPacket>();

    publisher.bind(source.stream);
    source.add(
      EncodedVideoPacket(
        data: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7]),
        presentationTimeUs: 987654,
        flags: 1,
      ),
    );
    await source.close();
    await Future<void>.delayed(Duration.zero);
    await publisher.dispose();

    expect(transport.sent, hasLength(3));

    final EncodedVideoReassembler reassembler = EncodedVideoReassembler();
    EncodedVideoPacket? restored;
    for (final Uint8List bytes in transport.sent) {
      restored = reassembler.add(codec.decode(bytes)) ?? restored;
    }

    expect(restored, isNotNull);
    expect(restored!.data, orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7]));
    expect(restored.presentationTimeUs, 987654);
    expect(restored.flags, 1);
  });
}
