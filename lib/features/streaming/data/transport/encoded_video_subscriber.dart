import 'dart:async';

import '../../domain/entities/encoded_video_packet.dart';
import '../../domain/repositories/binary_video_transport.dart';
import 'encoded_video_chunk_codec.dart';
import 'encoded_video_reassembler.dart';

class EncodedVideoSubscriber {
  EncodedVideoSubscriber({
    required BinaryVideoTransport transport,
    EncodedVideoChunkCodec codec = const EncodedVideoChunkCodec(),
    EncodedVideoReassembler? reassembler,
  }) : _transport = transport,
       _codec = codec,
       _reassembler = reassembler ?? EncodedVideoReassembler();

  final BinaryVideoTransport _transport;
  final EncodedVideoChunkCodec _codec;
  final EncodedVideoReassembler _reassembler;

  final StreamController<EncodedVideoPacket> _packetsController =
      StreamController<EncodedVideoPacket>.broadcast();
  StreamSubscription? _subscription;

  Stream<EncodedVideoPacket> get packets => _packetsController.stream;

  void start() {
    if (_subscription != null) {
      return;
    }

    _subscription = _transport.messages.listen((bytes) {
      try {
        final packet = _reassembler.add(_codec.decode(bytes));
        if (packet != null && !_packetsController.isClosed) {
          _packetsController.add(packet);
        }
      } catch (error, stackTrace) {
        if (!_packetsController.isClosed) {
          _packetsController.addError(error, stackTrace);
        }
      }
    }, onError: _packetsController.addError);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _reassembler.clear();
    await _transport.close();
    await _packetsController.close();
  }
}
