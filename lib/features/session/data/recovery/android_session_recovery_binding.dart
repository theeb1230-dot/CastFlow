import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../streaming/data/screen_capture/android_media_projection_session.dart';
import '../../domain/services/session_recovery_controller.dart';
import '../webrtc/webrtc_orchestrator.dart';

class AndroidSessionRecoveryBinding {
  AndroidSessionRecoveryBinding({
    required WebRtcOrchestrator orchestrator,
    required AndroidMediaProjectionSession projectionSession,
    required SessionRecoveryController controller,
  }) : _orchestrator = orchestrator,
       _projectionSession = projectionSession,
       _controller = controller;

  final WebRtcOrchestrator _orchestrator;
  final AndroidMediaProjectionSession _projectionSession;
  final SessionRecoveryController _controller;

  StreamSubscription<RTCPeerConnectionState>? _connectionSubscription;
  StreamSubscription<void>? _captureSubscription;

  void start() {
    _connectionSubscription ??= _orchestrator.connectionStates.listen(
      _handleConnectionState,
    );
    _captureSubscription ??= _projectionSession.interruptions.listen((_) {
      _controller.onCaptureInterrupted();
    });
  }

  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _captureSubscription?.cancel();
    _captureSubscription = null;
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _controller.onTransportRecovered();
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        unawaited(_controller.onTransportLost());
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        break;
    }
  }
}
