import 'dart:async';

import '../../domain/entities/signaling_message.dart';
import '../../domain/repositories/rtc_signaling_port.dart';
import '../../domain/repositories/signaling_transport.dart';

class SignalingSessionBridge {
  SignalingSessionBridge({
    required SignalingTransport transport,
    required RtcSignalingPort rtc,
  }) : _transport = transport,
       _rtc = rtc;

  final SignalingTransport _transport;
  final RtcSignalingPort _rtc;

  StreamSubscription<SignalingMessage>? _messageSubscription;
  StreamSubscription<Map<String, Object?>>? _iceSubscription;

  Future<void> start() async {
    if (_messageSubscription != null || _iceSubscription != null) {
      return;
    }

    _messageSubscription = _transport.messages.listen(_handleMessage);
    _iceSubscription = _rtc.localIceCandidates.listen((
      Map<String, Object?> payload,
    ) {
      unawaited(_transport.send(SignalingMessageType.iceCandidate, payload));
    });
  }

  Future<void> createAndSendOffer() async {
    final Map<String, Object?> payload = await _rtc.createOffer();
    await _transport.send(SignalingMessageType.offer, payload);
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _iceSubscription?.cancel();
    _messageSubscription = null;
    _iceSubscription = null;
  }

  Future<void> _handleMessage(SignalingMessage message) async {
    switch (message.type) {
      case SignalingMessageType.pairingHello:
      case SignalingMessageType.pairingAck:
        return;
      case SignalingMessageType.offer:
        final Map<String, Object?> answer = await _rtc.acceptOffer(
          message.payload,
        );
        await _transport.send(SignalingMessageType.answer, answer);
      case SignalingMessageType.answer:
        await _rtc.acceptAnswer(message.payload);
      case SignalingMessageType.iceCandidate:
        await _rtc.addRemoteCandidate(message.payload);
      case SignalingMessageType.bye:
        await dispose();
    }
  }
}
