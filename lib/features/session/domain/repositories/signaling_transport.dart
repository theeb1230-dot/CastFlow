import '../entities/signaling_message.dart';

abstract interface class SignalingTransport {
  Stream<SignalingMessage> get messages;

  Future<void> send(SignalingMessageType type, Map<String, Object?> payload);
}
