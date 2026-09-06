import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../streaming/data/webrtc/encoded_video_webrtc_session.dart';
import '../../../streaming/domain/entities/encoded_video_packet.dart';
import '../../domain/repositories/signaling_transport.dart';
import '../signaling/signaling_session_bridge.dart';
import '../webrtc/rtc_signaling_adapter.dart';
import '../webrtc/webrtc_orchestrator.dart';

enum PairingRtcState { idle, connecting, connected, disconnected, failed }

abstract interface class PairingRtcSessionPort {
  Stream<PairingRtcState> get states;

  Stream<EncodedVideoPacket> get remoteVideoPackets;

  Future<void> startSender(SignalingTransport transport);

  Future<void> startReceiver(SignalingTransport transport);

  Future<void> startVideoSender(Stream<EncodedVideoPacket> packets);

  Future<void> dispose();
}

class PairingRtcSession implements PairingRtcSessionPort {
  PairingRtcSession({WebRtcOrchestrator? orchestrator})
    : _orchestrator = orchestrator ?? WebRtcOrchestrator();

  static const String controlChannelLabel = 'castflow-control';
  static const String controlChannelProtocol = 'castflow-control-v1';

  final WebRtcOrchestrator _orchestrator;
  final StreamController<PairingRtcState> _stateController =
      StreamController<PairingRtcState>.broadcast();

  SignalingSessionBridge? _bridge;
  StreamSubscription<RTCPeerConnectionState>? _connectionSubscription;
  EncodedVideoWebRtcSession? _videoSession;
  PairingRtcState _state = PairingRtcState.idle;
  bool _disposed = false;

  @override
  Stream<PairingRtcState> get states => _stateController.stream;

  @override
  Stream<EncodedVideoPacket> get remoteVideoPackets {
    final EncodedVideoWebRtcSession? session = _videoSession;
    if (session == null) {
      throw StateError('PairingRtcSession has not started yet.');
    }
    return session.remotePackets;
  }

  @override
  Future<void> startSender(SignalingTransport transport) async {
    await _startCommon(transport);

    await _orchestrator.createDataChannel(
      label: controlChannelLabel,
      ordered: true,
      maxRetransmits: 3,
      protocol: controlChannelProtocol,
    );

    await _bridge!.createAndSendOffer();
  }

  @override
  Future<void> startReceiver(SignalingTransport transport) async {
    await _startCommon(transport);
    final EncodedVideoWebRtcSession videoSession = EncodedVideoWebRtcSession(
      orchestrator: _orchestrator,
    );
    videoSession.startReceiver();
    _videoSession = videoSession;
  }

  @override
  Future<void> startVideoSender(Stream<EncodedVideoPacket> packets) async {
    if (_disposed) {
      throw StateError('PairingRtcSession is disposed.');
    }
    if (_state != PairingRtcState.connected) {
      throw StateError('WebRTC must be connected before starting video.');
    }

    await _videoSession?.dispose();
    final EncodedVideoWebRtcSession videoSession = EncodedVideoWebRtcSession(
      orchestrator: _orchestrator,
      senderPackets: packets,
    );
    await videoSession.startSender();
    _videoSession = videoSession;
  }

  Future<void> _startCommon(SignalingTransport transport) async {
    if (_disposed) {
      throw StateError('PairingRtcSession is disposed.');
    }
    if (_bridge != null) {
      return;
    }

    _emit(PairingRtcState.connecting);
    await _orchestrator.initialize();

    _connectionSubscription = _orchestrator.connectionStates.listen(
      _handleConnectionState,
      onError: (_, _) => _emit(PairingRtcState.failed),
    );

    final SignalingSessionBridge bridge = SignalingSessionBridge(
      transport: transport,
      rtc: RtcSignalingAdapter(_orchestrator),
    );
    await bridge.start();
    _bridge = bridge;
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _emit(PairingRtcState.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _emit(PairingRtcState.disconnected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _emit(PairingRtcState.failed);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        _emit(PairingRtcState.connecting);
        break;
    }
  }

  void _emit(PairingRtcState value) {
    if (_disposed || value == _state || _stateController.isClosed) {
      return;
    }
    _state = value;
    _stateController.add(value);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _videoSession?.dispose();
    _videoSession = null;
    await _bridge?.dispose();
    _bridge = null;
    await _orchestrator.dispose();
    await _stateController.close();
  }
}
