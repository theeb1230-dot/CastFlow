import 'dart:async';

import 'package:castflow/features/session/data/pairing/pairing_rtc_session.dart';
import 'package:castflow/features/session/data/webrtc/webrtc_orchestrator.dart';
import 'package:castflow/features/session/domain/entities/signaling_message.dart';
import 'package:castflow/features/session/domain/repositories/signaling_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class _FakeTransport implements SignalingTransport {
  final StreamController<SignalingMessage> controller =
      StreamController<SignalingMessage>.broadcast();
  final List<SignalingMessageType> sentTypes = <SignalingMessageType>[];

  @override
  Stream<SignalingMessage> get messages => controller.stream;

  @override
  Future<void> send(
    SignalingMessageType type,
    Map<String, Object?> payload,
  ) async {
    sentTypes.add(type);
  }

  Future<void> dispose() => controller.close();
}

class _FakeOrchestrator extends WebRtcOrchestrator {
  final StreamController<RTCPeerConnectionState> stateController =
      StreamController<RTCPeerConnectionState>.broadcast();

  @override
  Stream<RTCPeerConnectionState> get connectionStates => stateController.stream;

  @override
  Stream<RTCIceCandidate> get localCandidates =>
      const Stream<RTCIceCandidate>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() => stateController.close();
}

void main() {
  test('receiver render heartbeat is sent over signaling transport', () async {
    final _FakeOrchestrator orchestrator = _FakeOrchestrator();
    final _FakeTransport transport = _FakeTransport();
    final PairingRtcSession session = PairingRtcSession(
      orchestrator: orchestrator,
    );

    await session.startReceiver(transport);
    await session.notifyVideoHeartbeat();

    expect(transport.sentTypes, contains(SignalingMessageType.videoHeartbeat));

    await session.dispose();
    await transport.dispose();
  });

  test('sender exposes incoming receiver render heartbeat', () async {
    final _FakeOrchestrator orchestrator = _FakeOrchestrator();
    final _FakeTransport transport = _FakeTransport();
    final PairingRtcSession session = PairingRtcSession(
      orchestrator: orchestrator,
    );

    await session.startReceiver(transport);
    final Future<void> heartbeat = session.videoHeartbeats.first;

    transport.controller.add(
      const SignalingMessage(
        type: SignalingMessageType.videoHeartbeat,
        sessionId: 'session-1',
        token: 'token-1',
        payload: <String, Object?>{'state': 'rendering'},
      ),
    );

    await heartbeat.timeout(const Duration(seconds: 1));

    await session.dispose();
    await transport.dispose();
  });
}
