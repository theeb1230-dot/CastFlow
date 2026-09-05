import '../webrtc/webrtc_orchestrator.dart';
import '../../domain/repositories/session_recovery_port.dart';

class WebRtcSessionRecoveryPort implements SessionRecoveryPort {
  WebRtcSessionRecoveryPort(this._orchestrator);

  final WebRtcOrchestrator _orchestrator;

  @override
  Future<void> restartTransport() {
    return _orchestrator.restartIce();
  }
}
