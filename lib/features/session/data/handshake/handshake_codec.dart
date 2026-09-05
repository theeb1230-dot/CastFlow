import 'dart:convert';
import 'dart:math';

import '../../domain/entities/handshake_payload.dart';

class HandshakeCodec {
  static const String prefix = 'castflow://pair/';
  static const int protocolVersion = 1;

  const HandshakeCodec();

  String encode(HandshakePayload payload) {
    final String json = jsonEncode(payload.toJson());
    final String data = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return '$prefix$data';
  }

  HandshakePayload decode(String value) {
    if (!value.startsWith(prefix)) {
      throw const FormatException('Unsupported CastFlow handshake payload.');
    }

    final String raw = value.substring(prefix.length);
    final String normalized = raw.padRight((raw.length + 3) ~/ 4 * 4, '=');
    final Object? decoded = jsonDecode(
      utf8.decode(base64Url.decode(normalized)),
    );

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid CastFlow handshake JSON.');
    }

    final HandshakePayload payload = HandshakePayload.fromJson(decoded);
    if (payload.version != protocolVersion) {
      throw FormatException(
        'Unsupported CastFlow protocol version: ${payload.version}.',
      );
    }
    if (payload.isExpired) {
      throw const FormatException('CastFlow handshake has expired.');
    }
    return payload;
  }

  HandshakePayload create({
    required String sessionId,
    required String peerId,
    required String peerName,
    required String host,
    required int port,
    Duration ttl = const Duration(minutes: 2),
  }) {
    final Random random = Random.secure();
    final List<int> tokenBytes = List<int>.generate(
      24,
      (_) => random.nextInt(256),
      growable: false,
    );

    return HandshakePayload(
      version: protocolVersion,
      sessionId: sessionId,
      peerId: peerId,
      peerName: peerName,
      host: host,
      port: port,
      expiresAtEpochSeconds:
          DateTime.now().toUtc().add(ttl).millisecondsSinceEpoch ~/ 1000,
      token: base64Url.encode(tokenBytes).replaceAll('=', ''),
    );
  }
}
