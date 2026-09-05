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
    this.maxClients = 8,
    SignalingCodec codec = const SignalingCodec(),
  }) : assert(maxClients > 0),
       address = address ?? InternetAddress.anyIPv4,
       _codec = codec;

  final String sessionId;
  final String token;
  final InternetAddress address;
  final int port;
  final int maxClients;
  final SignalingCodec _codec;

  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  final Set<Socket> _clients = <Socket>{};
  final Set<Socket> _authenticatedClients = <Socket>{};
  ServerSocket? _server;

  @override
  Stream<SignalingMessage> get messages => _messagesController.stream;

  int get connectedClientCount => _clients.length;
  int get authenticatedClientCount => _authenticatedClients.length;

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
    for (final Socket socket in _authenticatedClients.toList(growable: false)) {
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
    _authenticatedClients.clear();

    if (server != null) {
      await server.close();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }

  void _acceptClient(Socket socket) {
    if (_clients.length >= maxClients) {
      socket.destroy();
      return;
    }

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

              if (message.type == SignalingMessageType.pairingHello) {
                final Object? nonce = message.payload['nonce'];
                if (nonce is! String ||
                    nonce.length < 16 ||
                    nonce.length > 128) {
                  throw const FormatException(
                    'Invalid CastFlow pairing challenge.',
                  );
                }

                final SignalingMessage acknowledgement = SignalingMessage(
                  type: SignalingMessageType.pairingAck,
                  sessionId: sessionId,
                  token: token,
                  payload: <String, Object?>{'nonce': nonce},
                );
                _authenticatedClients.add(socket);
                socket.write('${_codec.encode(acknowledgement)}\n');
                unawaited(socket.flush());
                return;
              }

              if (!_authenticatedClients.contains(socket)) {
                throw const FormatException(
                  'CastFlow signaling client is not authenticated.',
                );
              }

              if (!_messagesController.isClosed) {
                _messagesController.add(message);
              }
            } catch (error, stackTrace) {
              if (!_messagesController.isClosed) {
                _messagesController.addError(error, stackTrace);
              }
              _authenticatedClients.remove(socket);
              socket.destroy();
            }
          },
          onDone: () {
            _clients.remove(socket);
            _authenticatedClients.remove(socket);
          },
          onError: (_, _) {
            _clients.remove(socket);
            _authenticatedClients.remove(socket);
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
