import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/entities/connection_metrics.dart';
import 'webrtc_stats_parser.dart';

class WebRtcOrchestrator {
  WebRtcOrchestrator({
    WebRtcStatsParser statsParser = const WebRtcStatsParser(),
  }) : _statsParser = statsParser;

  final WebRtcStatsParser _statsParser;
  RTCPeerConnection? _peerConnection;

  final StreamController<RTCIceCandidate> _localCandidatesController =
      StreamController<RTCIceCandidate>.broadcast();
  final StreamController<RTCPeerConnectionState> _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();

  Stream<RTCIceCandidate> get localCandidates =>
      _localCandidatesController.stream;
  Stream<RTCPeerConnectionState> get connectionStates =>
      _connectionStateController.stream;

  Future<void> initialize() async {
    if (_peerConnection != null) {
      return;
    }

    final RTCPeerConnection peerConnection = await createPeerConnection(
      <String, dynamic>{
        'iceServers': <Object>[],
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'sdpSemantics': 'unified-plan',
      },
      <String, dynamic>{
        'mandatory': <String, dynamic>{},
        'optional': <Object>[],
      },
    );

    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate?.isNotEmpty ?? false) {
        _localCandidatesController.add(candidate);
      }
    };
    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      _connectionStateController.add(state);
    };

    _peerConnection = peerConnection;
  }

  Future<RTCSessionDescription> createOffer() async {
    final RTCPeerConnection peerConnection = _requirePeerConnection();
    final RTCSessionDescription offer = await peerConnection.createOffer(
      <String, dynamic>{
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': true,
      },
    );
    await peerConnection.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> acceptOffer(
    RTCSessionDescription remoteOffer,
  ) async {
    final RTCPeerConnection peerConnection = _requirePeerConnection();
    await peerConnection.setRemoteDescription(remoteOffer);
    final RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    return answer;
  }

  Future<void> acceptAnswer(RTCSessionDescription remoteAnswer) {
    return _requirePeerConnection().setRemoteDescription(remoteAnswer);
  }

  Future<void> addRemoteCandidate(RTCIceCandidate candidate) {
    return _requirePeerConnection().addCandidate(candidate);
  }

  Future<void> restartIce() {
    return _requirePeerConnection().restartIce();
  }

  Future<ConnectionMetrics> collectConnectionMetrics() async {
    final List<StatsReport> reports = await _requirePeerConnection().getStats();
    return _statsParser.parse(reports);
  }

  Future<void> dispose() async {
    final RTCPeerConnection? peerConnection = _peerConnection;
    _peerConnection = null;
    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }
    await _localCandidatesController.close();
    await _connectionStateController.close();
  }

  RTCPeerConnection _requirePeerConnection() {
    final RTCPeerConnection? peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('WebRtcOrchestrator.initialize() must be called first.');
    }
    return peerConnection;
  }
}
