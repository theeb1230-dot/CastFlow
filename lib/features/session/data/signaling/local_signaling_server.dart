import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/signaling_message.dart';
import '../../domain/entities/handshake_payload.dart';
import '../../domain/repositories/signaling_transport.dart';
import 'signaling_codec.dart';

class LocalSignalingServer implements SignalingTransport {
  LocalSignalingServer({
    required this.sessionId,
    required this.token,
    InternetAddress? address,
    this.port = 0,
    SignalingCodec codec = const SignalingCodec(),
  }) : address = address ?? InternetAddress.anyIPv4,
       _codec = codec;

  final String sessionId;
  final String token;
  final InternetAddress address;
  final int port;
  final SignalingCodec _codec;

  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  final Set<Socket> _clients = <Socket>{};
  ServerSocket? _server;

  @override
  Stream<SignalingMessage> get messages => _messagesController.stream;

  int get boundPort {
    final ServerSocket? server = _server;
    if (server == null) {
      throw StateError('LocalSignalingServer has not been started.');
    }
    return server.port;
  }

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    final ServerSocket server = await ServerSocket.bind(address, port);
    _server = server;
    server.listen(_acceptClient);
  }

  @override
  Future<void> send(
    SignalingMessageType type,
    Map<String, Object?> payload,
  ) async {
    final SignalingMessage message = SignalingMessage(
      type: type,
      sessionId: sessionId,
      token: token,
      payload: payload,
    );

    final List<int> bytes = utf8.encode('${_codec.encode(message)}\n');
    for (final Socket socket in _clients.toList(growable: false)) {
      socket.add(bytes);
      await socket.flush();
    }
  }

  Future<void> stop() async {
    final ServerSocket? server = _server;
    _server = null;

    for (final Socket socket in _clients.toList(growable: false)) {
      await socket.close();
    }
    _clients.clear();

    if (server != null) {
      await server.close();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }

  void _acceptClient(Socket socket) {
    _clients.add(socket);

    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            try {
              final SignalingMessage message = _codec.decode(line);
              _validateEnvelope(message);
              if (!_messagesController.isClosed) {
                _messagesController.add(message);
              }
            } catch (error, stackTrace) {
              if (!_messagesController.isClosed) {
                _messagesController.addError(error, stackTrace);
              }
              socket.destroy();
            }
          },
          onDone: () => _clients.remove(socket),
          onError: (_, _) {
            _clients.remove(socket);
            socket.destroy();
          },
          cancelOnError: true,
        );
  }

  void _validateEnvelope(SignalingMessage message) {
    if (message.sessionId != sessionId || message.token != token) {
      throw const FormatException('Invalid CastFlow signaling credentials.');
    }
  }

  factory LocalSignalingServer.fromHandshake(HandshakePayload handshake) {
    return LocalSignalingServer(
      sessionId: handshake.sessionId,
      token: handshake.token,
      port: handshake.port,
    );
  }
}
