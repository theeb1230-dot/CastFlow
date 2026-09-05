import 'dart:async';

import '../../domain/entities/encoded_video_packet.dart';
import '../../domain/repositories/binary_video_transport.dart';
import 'encoded_video_chunk_codec.dart';

class EncodedVideoPublisher {
  EncodedVideoPublisher({
    required BinaryVideoTransport transport,
    EncodedVideoChunkCodec codec = const EncodedVideoChunkCodec(),
  }) : _transport = transport,
       _codec = codec;

  final BinaryVideoTransport _transport;
  final EncodedVideoChunkCodec _codec;

  StreamSubscription<EncodedVideoPacket>? _subscription;
  int _sequence = 0;
  Future<void> _sendTail = Future<void>.value();

  void bind(Stream<EncodedVideoPacket> packets) {
    if (_subscription != null) {
      throw StateError('EncodedVideoPublisher is already bound.');
    }

    _subscription = packets.listen((EncodedVideoPacket packet) {
      final int sequence = _sequence++;
      _sendTail = _sendTail.then((_) => _sendPacket(packet, sequence));
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _sendTail;
    await _transport.close();
  }

  Future<void> _sendPacket(EncodedVideoPacket packet, int sequence) async {
    final chunks = _codec.split(packet: packet, sequence: sequence);
    for (final chunk in chunks) {
      await _transport.send(_codec.encode(chunk));
    }
  }
}
