import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/services/session_recovery_controller.dart';
import 'ios_replaykit_lifecycle_source.dart';

class IosSessionRecoveryBinding {
  IosSessionRecoveryBinding({
    required Stream<RTCPeerConnectionState> connectionStates,
    required Stream<ReplayKitLifecycleSnapshot> replayKitLifecycle,
    required Stream<AppLifecycleState> appLifecycleStates,
    required SessionRecoveryController controller,
  }) : _connectionStates = connectionStates,
       _replayKitLifecycle = replayKitLifecycle,
       _appLifecycleStates = appLifecycleStates,
       _controller = controller;

  final Stream<RTCPeerConnectionState> _connectionStates;
  final Stream<ReplayKitLifecycleSnapshot> _replayKitLifecycle;
  final Stream<AppLifecycleState> _appLifecycleStates;
  final SessionRecoveryController _controller;

  StreamSubscription<RTCPeerConnectionState>? _connectionSubscription;
  StreamSubscription<ReplayKitLifecycleSnapshot>? _replayKitSubscription;
  StreamSubscription<AppLifecycleState>? _appLifecycleSubscription;

  RTCPeerConnectionState? _lastConnectionState;
  bool _foreground = true;

  void start() {
    _connectionSubscription ??= _connectionStates.listen(
      _handleConnectionState,
    );
    _replayKitSubscription ??= _replayKitLifecycle.listen(
      _handleReplayKitState,
    );
    _appLifecycleSubscription ??= _appLifecycleStates.listen(
      _handleAppLifecycleState,
    );
  }

  Future<void> dispose() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    await _replayKitSubscription?.cancel();
    _replayKitSubscription = null;

    await _appLifecycleSubscription?.cancel();
    _appLifecycleSubscription = null;
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    _lastConnectionState = state;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _controller.onTransportRecovered();
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        if (_foreground) {
          _requestRecovery();
        }
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        break;
    }
  }

  void _handleReplayKitState(ReplayKitLifecycleSnapshot snapshot) {
    switch (snapshot.state) {
      case ReplayKitLifecycleState.started:
      case ReplayKitLifecycleState.resumed:
        if (_controller.state ==
            SessionRecoveryState.capturePermissionRequired) {
          _controller.resetAfterCaptureConsent();
        }
      case ReplayKitLifecycleState.finished:
      case ReplayKitLifecycleState.encoderError:
        _controller.onCaptureInterrupted();
      case ReplayKitLifecycleState.idle:
      case ReplayKitLifecycleState.paused:
      case ReplayKitLifecycleState.unknown:
        break;
    }
  }

  void _handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        final RTCPeerConnectionState? last = _lastConnectionState;
        if (last == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            last == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _requestRecovery();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
    }
  }

  void _requestRecovery() {
    final Future<void> recovery = _controller
        .onTransportLost()
        .then<void>((SessionRecoveryState _) {})
        .onError((Object _, StackTrace _) {});
    unawaited(recovery);
  }
}
