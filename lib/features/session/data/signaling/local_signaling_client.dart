import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/signaling_message.dart';
import 'signaling_codec.dart';

class LocalSignalingClient {
  LocalSignalingClient({
    required this.host,
    required this.port,
    required this.sessionId,
    required this.token,
    SignalingCodec codec = const SignalingCodec(),
  }) : _codec = codec;

  final String host;
  final int port;
  final String sessionId;
  final String token;
  final SignalingCodec _codec;

  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  Socket? _socket;
  StreamSubscription<String>? _subscription;

  Stream<SignalingMessage> get messages => _messagesController.stream;

  Future<void> connect({Duration timeout = const Duration(seconds: 5)}) async {
    if (_socket != null) {
      return;
    }

    final Socket socket = await Socket.connect(host, port, timeout: timeout);
    _socket = socket;

    _subscription = socket
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
            }
          },
          onDone: () {
            _socket = null;
          },
          onError: (Object error, StackTrace stackTrace) {
            _socket = null;
            if (!_messagesController.isClosed) {
              _messagesController.addError(error, stackTrace);
            }
          },
        );
  }

  Future<void> send(
    SignalingMessageType type,
    Map<String, Object?> payload,
  ) async {
    final Socket? socket = _socket;
    if (socket == null) {
      throw StateError('LocalSignalingClient is not connected.');
    }

    final SignalingMessage message = SignalingMessage(
      type: type,
      sessionId: sessionId,
      token: token,
      payload: payload,
    );

    socket.write('${_codec.encode(message)}\n');
    await socket.flush();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    final Socket? socket = _socket;
    _socket = null;
    await socket?.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
  }

  void _validateEnvelope(SignalingMessage message) {
    if (message.sessionId != sessionId || message.token != token) {
      throw const FormatException('Invalid CastFlow signaling credentials.');
    }
  }
}
