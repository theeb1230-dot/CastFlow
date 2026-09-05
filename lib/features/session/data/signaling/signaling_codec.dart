import 'dart:convert';

import '../../domain/entities/signaling_message.dart';

class SignalingCodec {
  const SignalingCodec();

  String encode(SignalingMessage message) {
    return jsonEncode(<String, Object?>{
      'type': message.type.name,
      'sid': message.sessionId,
      'token': message.token,
      'payload': message.payload,
    });
  }

  SignalingMessage decode(String value) {
    final Object? decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Signaling message must be a JSON object.');
    }

    final Object? typeValue = decoded['type'];
    final Object? sessionId = decoded['sid'];
    final Object? token = decoded['token'];
    final Object? payload = decoded['payload'];

    if (typeValue is! String ||
        sessionId is! String ||
        sessionId.isEmpty ||
        token is! String ||
        token.isEmpty ||
        payload is! Map<String, dynamic>) {
      throw const FormatException('Signaling message contains invalid fields.');
    }

    final SignalingMessageType type;
    try {
      type = SignalingMessageType.values.byName(typeValue);
    } on ArgumentError {
      throw FormatException('Unsupported signaling type: $typeValue');
    }

    return SignalingMessage(
      type: type,
      sessionId: sessionId,
      token: token,
      payload: Map<String, Object?>.from(payload),
    );
  }
}
