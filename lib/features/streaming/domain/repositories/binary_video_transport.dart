import 'dart:typed_data';

abstract interface class BinaryVideoTransport {
  Stream<Uint8List> get messages;

  Future<void> send(Uint8List bytes);

  Future<void> close();
}
