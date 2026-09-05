import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/repositories/rtc_signaling_port.dart';
import 'webrtc_orchestrator.dart';

class RtcSignalingAdapter implements RtcSignalingPort {
  RtcSignalingAdapter(this._orchestrator);

  final WebRtcOrchestrator _orchestrator;

  @override
  Stream<Map<String, Object?>> get localIceCandidates {
    return _orchestrator.localCandidates.map(_candidateToPayload);
  }

  @override
  Future<Map<String, Object?>> createOffer() async {
    final RTCSessionDescription offer = await _orchestrator.createOffer();
    return _descriptionToPayload(offer);
  }

  @override
  Future<Map<String, Object?>> acceptOffer(Map<String, Object?> payload) async {
    final RTCSessionDescription answer = await _orchestrator.acceptOffer(
      _descriptionFromPayload(payload),
    );
    return _descriptionToPayload(answer);
  }

  @override
  Future<void> acceptAnswer(Map<String, Object?> payload) {
    return _orchestrator.acceptAnswer(_descriptionFromPayload(payload));
  }

  @override
  Future<void> addRemoteCandidate(Map<String, Object?> payload) {
    return _orchestrator.addRemoteCandidate(_candidateFromPayload(payload));
  }

  Map<String, Object?> _descriptionToPayload(
    RTCSessionDescription description,
  ) {
    return <String, Object?>{
      'sdp': description.sdp,
      'type': description.type,
    };
  }

  RTCSessionDescription _descriptionFromPayload(
    Map<String, Object?> payload,
  ) {
    final Object? sdp = payload['sdp'];
    final Object? type = payload['type'];

    if (sdp is! String || sdp.isEmpty || type is! String || type.isEmpty) {
      throw const FormatException('Invalid WebRTC session description.');
    }

    return RTCSessionDescription(sdp, type);
  }

  Map<String, Object?> _candidateToPayload(RTCIceCandidate candidate) {
    return <String, Object?>{
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
  }

  RTCIceCandidate _candidateFromPayload(Map<String, Object?> payload) {
    final Object? candidate = payload['candidate'];
    final Object? sdpMid = payload['sdpMid'];
    final Object? sdpMLineIndex = payload['sdpMLineIndex'];

    if (candidate is! String || candidate.isEmpty) {
      throw const FormatException('Invalid WebRTC ICE candidate.');
    }
    if (sdpMid != null && sdpMid is! String) {
      throw const FormatException('Invalid WebRTC ICE sdpMid.');
    }
    if (sdpMLineIndex != null && sdpMLineIndex is! int) {
      throw const FormatException('Invalid WebRTC ICE m-line index.');
    }

    return RTCIceCandidate(
      candidate,
      sdpMid as String?,
      sdpMLineIndex as int?,
    );
  }
}
