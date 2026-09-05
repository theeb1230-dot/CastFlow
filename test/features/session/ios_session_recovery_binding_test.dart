import 'dart:async';

import 'package:castflow/features/session/data/recovery/ios_replaykit_lifecycle_source.dart';
import 'package:castflow/features/session/data/recovery/ios_session_recovery_binding.dart';
import 'package:castflow/features/session/domain/repositories/session_recovery_port.dart';
import 'package:castflow/features/session/domain/services/session_recovery_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class _FakeRecoveryPort implements SessionRecoveryPort {
  int restartCalls = 0;

  @override
  Future<void> restartTransport() async {
    restartCalls += 1;
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('decodes ReplayKit lifecycle snapshots', () {
    const ReplayKitLifecycleEventDecoder decoder =
        ReplayKitLifecycleEventDecoder();

    final ReplayKitLifecycleSnapshot snapshot = decoder.decode(<String, Object>{
      'state': 'encoder-error',
      'lastHeartbeat': 123.5,
      'videoSamples': 42,
    });

    expect(snapshot.state, ReplayKitLifecycleState.encoderError);
    expect(snapshot.lastHeartbeatSeconds, 123.5);
    expect(snapshot.videoSamples, 42);
  });

  test(
    'suppresses reconnect while backgrounded and retries on resume',
    () async {
      final StreamController<RTCPeerConnectionState> connections =
          StreamController<RTCPeerConnectionState>.broadcast();
      final StreamController<ReplayKitLifecycleSnapshot> replayKit =
          StreamController<ReplayKitLifecycleSnapshot>.broadcast();
      final StreamController<AppLifecycleState> appLifecycle =
          StreamController<AppLifecycleState>.broadcast();
      final _FakeRecoveryPort port = _FakeRecoveryPort();
      final SessionRecoveryController controller = SessionRecoveryController(
        port: port,
        sleeper: (_) async {},
      );
      final IosSessionRecoveryBinding binding = IosSessionRecoveryBinding(
        connectionStates: connections.stream,
        replayKitLifecycle: replayKit.stream,
        appLifecycleStates: appLifecycle.stream,
        controller: controller,
      )..start();

      appLifecycle.add(AppLifecycleState.paused);
      connections.add(
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected,
      );
      await _flushEvents();
      expect(port.restartCalls, 0);

      appLifecycle.add(AppLifecycleState.resumed);
      await _flushEvents();
      expect(port.restartCalls, 1);

      await binding.dispose();
      await connections.close();
      await replayKit.close();
      await appLifecycle.close();
    },
  );

  test(
    'ReplayKit finish blocks transport restart until capture resumes',
    () async {
      final StreamController<RTCPeerConnectionState> connections =
          StreamController<RTCPeerConnectionState>.broadcast();
      final StreamController<ReplayKitLifecycleSnapshot> replayKit =
          StreamController<ReplayKitLifecycleSnapshot>.broadcast();
      final StreamController<AppLifecycleState> appLifecycle =
          StreamController<AppLifecycleState>.broadcast();
      final _FakeRecoveryPort port = _FakeRecoveryPort();
      final SessionRecoveryController controller = SessionRecoveryController(
        port: port,
        sleeper: (_) async {},
      );
      final IosSessionRecoveryBinding binding = IosSessionRecoveryBinding(
        connectionStates: connections.stream,
        replayKitLifecycle: replayKit.stream,
        appLifecycleStates: appLifecycle.stream,
        controller: controller,
      )..start();

      replayKit.add(
        const ReplayKitLifecycleSnapshot(
          state: ReplayKitLifecycleState.finished,
          lastHeartbeatSeconds: 0,
          videoSamples: 0,
        ),
      );
      await _flushEvents();
      expect(controller.state, SessionRecoveryState.capturePermissionRequired);

      connections.add(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
      await _flushEvents();
      expect(port.restartCalls, 0);

      replayKit.add(
        const ReplayKitLifecycleSnapshot(
          state: ReplayKitLifecycleState.started,
          lastHeartbeatSeconds: 1,
          videoSamples: 1,
        ),
      );
      await _flushEvents();
      expect(controller.state, SessionRecoveryState.connected);

      await binding.dispose();
      await connections.close();
      await replayKit.close();
      await appLifecycle.close();
    },
  );
}
