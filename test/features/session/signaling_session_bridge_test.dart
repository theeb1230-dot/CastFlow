import 'dart:async';

import 'package:castflow/features/session/data/signaling/signaling_session_bridge.dart';
import 'package:castflow/features/session/domain/entities/signaling_message.dart';
import 'package:castflow/features/session/domain/repositories/rtc_signaling_port.dart';
import 'package:castflow/features/session/domain/repositories/signaling_transport.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransport implements SignalingTransport {
  final StreamController<SignalingMessage> controller =
      StreamController<SignalingMessage>.broadcast();

  final List<(SignalingMessageType, Map<String, Object?>)> sent =
      <(SignalingMessageType, Map<String, Object?>)>[];

  @override
  Stream<SignalingMessage> get messages => controller.stream;

  @override
  Future<void> send(
    SignalingMessageType type,
    Map<String, Object?> payload,
  ) async {
    sent.add((type, payload));
  }

  Future<void> dispose() => controller.close();
}

class _FakeRtc implements RtcSignalingPort {
  final StreamController<Map<String, Object?>> iceController =
      StreamController<Map<String, Object?>>.broadcast();

  Map<String, Object?>? acceptedAnswer;
  Map<String, Object?>? acceptedCandidate;
  Map<String, Object?>? acceptedOffer;

  @override
  Stream<Map<String, Object?>> get localIceCandidates => iceController.stream;

  @override
  Future<Map<String, Object?>> createOffer() async {
    return <String, Object?>{'sdp': 'offer-sdp', 'type': 'offer'};
  }

  @override
  Future<Map<String, Object?>> acceptOffer(
    Map<String, Object?> payload,
  ) async {
    acceptedOffer = payload;
    return <String, Object?>{'sdp': 'answer-sdp', 'type': 'answer'};
  }

  @override
  Future<void> acceptAnswer(Map<String, Object?> payload) async {
    acceptedAnswer = payload;
  }

  @override
  Future<void> addRemoteCandidate(Map<String, Object?> payload) async {
    acceptedCandidate = payload;
  }

  Future<void> dispose() => iceController.close();
}

void main() {
  test('creates and sends an SDP offer', () async {
    final _FakeTransport transport = _FakeTransport();
    final _FakeRtc rtc = _FakeRtc();
    final SignalingSessionBridge bridge = SignalingSessionBridge(
      transport: transport,
      rtc: rtc,
    );

    await bridge.start();
    await bridge.createAndSendOffer();

    expect(transport.sent.single.$1, SignalingMessageType.offer);
    expect(transport.sent.single.$2['sdp'], 'offer-sdp');

    await bridge.dispose();
    await transport.dispose();
    await rtc.dispose();
  });

  test('accepts offer and sends answer', () async {
    final _FakeTransport transport = _FakeTransport();
    final _FakeRtc rtc = _FakeRtc();
    final SignalingSessionBridge bridge = SignalingSessionBridge(
      transport: transport,
      rtc: rtc,
    );

    await bridge.start();

    transport.controller.add(
      const SignalingMessage(
        type: SignalingMessageType.offer,
        sessionId: 's',
        token: 't',
        payload: <String, Object?>{'sdp': 'remote', 'type': 'offer'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(rtc.acceptedOffer?['sdp'], 'remote');
    expect(transport.sent.single.$1, SignalingMessageType.answer);
    expect(transport.sent.single.$2['sdp'], 'answer-sdp');

    await bridge.dispose();
    await transport.dispose();
    await rtc.dispose();
  });

  test('forwards local and remote ICE candidates', () async {
    final _FakeTransport transport = _FakeTransport();
    final _FakeRtc rtc = _FakeRtc();
    final SignalingSessionBridge bridge = SignalingSessionBridge(
      transport: transport,
      rtc: rtc,
    );

    await bridge.start();

    rtc.iceController.add(
      const <String, Object?>{'candidate': 'local-candidate'},
    );
    transport.controller.add(
      const SignalingMessage(
        type: SignalingMessageType.iceCandidate,
        sessionId: 's',
        token: 't',
        payload: <String, Object?>{'candidate': 'remote-candidate'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(transport.sent.single.$1, SignalingMessageType.iceCandidate);
    expect(rtc.acceptedCandidate?['candidate'], 'remote-candidate');

    await bridge.dispose();
    await transport.dispose();
    await rtc.dispose();
  });
}
