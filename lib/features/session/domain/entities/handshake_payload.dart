import 'package:equatable/equatable.dart';

class HandshakePayload extends Equatable {
  const HandshakePayload({
    required this.version,
    required this.sessionId,
    required this.peerId,
    required this.peerName,
    required this.host,
    required this.port,
    required this.expiresAtEpochSeconds,
    required this.token,
  });

  final int version;
  final String sessionId;
  final String peerId;
  final String peerName;
  final String host;
  final int port;
  final int expiresAtEpochSeconds;
  final String token;

  bool get isExpired =>
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 >=
      expiresAtEpochSeconds;

  Map<String, Object> toJson() => <String, Object>{
    'v': version,
    'sid': sessionId,
    'pid': peerId,
    'name': peerName,
    'host': host,
    'port': port,
    'exp': expiresAtEpochSeconds,
    'token': token,
  };

  factory HandshakePayload.fromJson(Map<String, dynamic> json) {
    return HandshakePayload(
      version: json['v'] as int,
      sessionId: json['sid'] as String,
      peerId: json['pid'] as String,
      peerName: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      expiresAtEpochSeconds: json['exp'] as int,
      token: json['token'] as String,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    version,
    sessionId,
    peerId,
    peerName,
    host,
    port,
    expiresAtEpochSeconds,
    token,
  ];
}
