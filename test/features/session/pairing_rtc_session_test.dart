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

  @override
  Stream<SignalingMessage> get messages => controller.stream;

  @override
  Future<void> send(
    SignalingMessageType type,
    Map<String, Object?> payload,
  ) async {}

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
  test(
    'receiver pairing becomes connected only after real RTC state',
    () async {
      final _FakeOrchestrator orchestrator = _FakeOrchestrator();
      final _FakeTransport transport = _FakeTransport();
      final PairingRtcSession session = PairingRtcSession(
        orchestrator: orchestrator,
      );

      final List<PairingRtcState> states = <PairingRtcState>[];
      final StreamSubscription<PairingRtcState> subscription = session.states
          .listen(states.add);

      await session.startReceiver(transport);
      expect(states, contains(PairingRtcState.connecting));
      expect(states, isNot(contains(PairingRtcState.connected)));

      orchestrator.stateController.add(
        RTCPeerConnectionState.RTCPeerConnectionStateConnected,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.last, PairingRtcState.connected);

      await subscription.cancel();
      await session.dispose();
      await transport.dispose();
    },
  );

  test('RTC failure is surfaced instead of reporting a false pair', () async {
    final _FakeOrchestrator orchestrator = _FakeOrchestrator();
    final _FakeTransport transport = _FakeTransport();
    final PairingRtcSession session = PairingRtcSession(
      orchestrator: orchestrator,
    );

    final Future<PairingRtcState> failed = session.states.firstWhere(
      (PairingRtcState value) => value == PairingRtcState.failed,
    );

    await session.startReceiver(transport);
    orchestrator.stateController.add(
      RTCPeerConnectionState.RTCPeerConnectionStateFailed,
    );

    expect(await failed, PairingRtcState.failed);

    await session.dispose();
    await transport.dispose();
  });
}
