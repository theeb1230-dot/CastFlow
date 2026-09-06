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

  Future<void> _messageTail = Future<void>.value();
  Future<void> _sendTail = Future<void>.value();
  final List<Map<String, Object?>> _pendingLocalIce = <Map<String, Object?>>[];
  bool _localDescriptionSignaled = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_messageSubscription != null || _iceSubscription != null) {
      return;
    }
    if (_disposed) {
      throw StateError('SignalingSessionBridge is disposed.');
    }

    _messageSubscription = _transport.messages.listen((
      SignalingMessage message,
    ) {
      _messageTail = _messageTail.then((_) => _handleMessage(message));
    });
    _iceSubscription = _rtc.localIceCandidates.listen(_handleLocalIce);
  }

  Future<void> createAndSendOffer() async {
    final Map<String, Object?> payload = await _rtc.createOffer();
    await _send(SignalingMessageType.offer, payload);
    _localDescriptionSignaled = true;
    await _flushPendingLocalIce();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _messageSubscription?.cancel();
    await _iceSubscription?.cancel();
    _messageSubscription = null;
    _iceSubscription = null;

    try {
      await _messageTail;
      await _sendTail;
    } finally {
      _pendingLocalIce.clear();
    }
  }

  void _handleLocalIce(Map<String, Object?> payload) {
    if (_disposed) {
      return;
    }
    if (!_localDescriptionSignaled) {
      _pendingLocalIce.add(Map<String, Object?>.from(payload));
      return;
    }
    unawaited(_send(SignalingMessageType.iceCandidate, payload));
  }

  Future<void> _flushPendingLocalIce() async {
    if (_pendingLocalIce.isEmpty) {
      return;
    }
    final List<Map<String, Object?>> pending = List<Map<String, Object?>>.from(
      _pendingLocalIce,
    );
    _pendingLocalIce.clear();
    for (final Map<String, Object?> payload in pending) {
      await _send(SignalingMessageType.iceCandidate, payload);
    }
  }

  Future<void> _send(SignalingMessageType type, Map<String, Object?> payload) {
    final Future<void> previous = _sendTail;
    final Future<void> operation = () async {
      try {
        await previous;
      } catch (_) {
        // A previous send failure must not permanently poison the queue.
      }
      await _transport.send(type, payload);
    }();

    _sendTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _handleMessage(SignalingMessage message) async {
    if (_disposed) {
      return;
    }

    switch (message.type) {
      case SignalingMessageType.pairingHello:
      case SignalingMessageType.pairingAck:
        return;
      case SignalingMessageType.offer:
        final Map<String, Object?> answer = await _rtc.acceptOffer(
          message.payload,
        );
        await _send(SignalingMessageType.answer, answer);
        _localDescriptionSignaled = true;
        await _flushPendingLocalIce();
        return;
      case SignalingMessageType.answer:
        await _rtc.acceptAnswer(message.payload);
        return;
      case SignalingMessageType.iceCandidate:
        await _rtc.addRemoteCandidate(message.payload);
        return;
      case SignalingMessageType.bye:
        unawaited(Future<void>.delayed(Duration.zero, dispose));
        return;
    }
  }
}
