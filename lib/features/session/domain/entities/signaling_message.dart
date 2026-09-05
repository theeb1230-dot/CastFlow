import 'package:equatable/equatable.dart';

enum SignalingMessageType { offer, answer, iceCandidate, bye }

class SignalingMessage extends Equatable {
  const SignalingMessage({
    required this.type,
    required this.sessionId,
    required this.token,
    required this.payload,
  });

  final SignalingMessageType type;
  final String sessionId;
  final String token;
  final Map<String, Object?> payload;

  @override
  List<Object?> get props => <Object?>[type, sessionId, token, payload];
}
