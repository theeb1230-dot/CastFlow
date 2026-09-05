import 'dart:convert';

import 'package:equatable/equatable.dart';

class PairingPayload extends Equatable {
  const PairingPayload({
    required this.sessionId,
    required this.host,
    required this.port,
    required this.expiresAt,
    required this.protocolVersion,
  });

  final String sessionId;
  final String host;
  final int port;
  final DateTime expiresAt;
  final int protocolVersion;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  String encode() {
    final Map<String, Object> json = <String, Object>{
      'v': protocolVersion,
      'sid': sessionId,
      'host': host,
      'port': port,
      'exp': expiresAt.toUtc().millisecondsSinceEpoch,
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  factory PairingPayload.decode(String encoded) {
    final String normalized = base64Url.normalize(encoded);
    final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Pairing payload is not an object.');
    }

    final Object? version = decoded['v'];
    final Object? sessionId = decoded['sid'];
    final Object? host = decoded['host'];
    final Object? port = decoded['port'];
    final Object? expiry = decoded['exp'];

    if (version is! int ||
        sessionId is! String ||
        sessionId.isEmpty ||
        host is! String ||
        host.isEmpty ||
        port is! int ||
        port < 1 ||
        port > 65535 ||
        expiry is! int) {
      throw const FormatException('Pairing payload contains invalid fields.');
    }

    return PairingPayload(
      sessionId: sessionId,
      host: host,
      port: port,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiry, isUtc: true),
      protocolVersion: version,
    );
  }

  @override
  List<Object> get props => <Object>[
    sessionId,
    host,
    port,
    expiresAt.toUtc(),
    protocolVersion,
  ];
}
