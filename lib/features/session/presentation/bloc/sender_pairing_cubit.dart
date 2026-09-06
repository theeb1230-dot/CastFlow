import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../streaming/data/encoder/android_hardware_encoder.dart';
import '../../../streaming/data/screen_capture/android_media_projection_session.dart';
import '../../../streaming/domain/entities/streaming_profile.dart';
import '../../data/pairing/pairing_qr_codec.dart';
import '../../data/pairing/pairing_rtc_session.dart';
import '../../data/signaling/local_signaling_client.dart';
import '../../domain/entities/handshake_payload.dart';

enum SenderPairingStatus {
  idle,
  connecting,
  startingStream,
  streaming,
  failure,
}

class SenderPairingState extends Equatable {
  const SenderPairingState({
    this.status = SenderPairingStatus.idle,
    this.peerName,
    this.errorMessage,
  });

  final SenderPairingStatus status;
  final String? peerName;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[status, peerName, errorMessage];
}

class SenderPairingCubit extends Cubit<SenderPairingState> {
  SenderPairingCubit({
    PairingQrCodec codec = const PairingQrCodec(),
    PairingRtcSessionPort Function()? rtcSessionFactory,
    AndroidMediaProjectionSession? projectionSession,
    AndroidHardwareEncoder? encoder,
  }) : _codec = codec,
       _rtcSessionFactory = rtcSessionFactory ?? PairingRtcSession.new,
       _projectionSession =
           projectionSession ?? AndroidMediaProjectionSession(),
       _encoder = encoder ?? AndroidHardwareEncoder(),
       super(const SenderPairingState());

  final PairingQrCodec _codec;
  final PairingRtcSessionPort Function() _rtcSessionFactory;
  final AndroidMediaProjectionSession _projectionSession;
  final AndroidHardwareEncoder _encoder;

  LocalSignalingClient? _client;
  PairingRtcSessionPort? _rtcSession;
  StreamSubscription<PairingRtcState>? _rtcStateSubscription;
  StreamSubscription<void>? _projectionInterruptionSubscription;

  Future<void> pair(String qrData) async {
    if (state.status == SenderPairingStatus.connecting ||
        state.status == SenderPairingStatus.startingStream) {
      return;
    }

    emit(const SenderPairingState(status: SenderPairingStatus.connecting));

    LocalSignalingClient? client;
    PairingRtcSessionPort? rtcSession;

    try {
      final HandshakePayload payload = _codec.decode(qrData);
      client = LocalSignalingClient(
        host: payload.host,
        port: payload.port,
        sessionId: payload.sessionId,
        token: payload.token,
      );
      await client.connectAuthenticated();

      rtcSession = _rtcSessionFactory();
      final Future<PairingRtcState> terminalState = rtcSession.states
          .firstWhere(
            (PairingRtcState value) =>
                value == PairingRtcState.connected ||
                value == PairingRtcState.failed ||
                value == PairingRtcState.disconnected,
          )
          .timeout(const Duration(seconds: 15));

      await rtcSession.startSender(client);

      final PairingRtcState result = await terminalState;
      if (result != PairingRtcState.connected) {
        throw StateError('تعذر إنشاء اتصال WebRTC فعلي مع جهاز الاستقبال.');
      }

      await _disposeActiveSession();
      _client = client;
      _rtcSession = rtcSession;
      client = null;
      rtcSession = null;

      _rtcStateSubscription = _rtcSession!.states.listen((
        PairingRtcState value,
      ) {
        if (value == PairingRtcState.failed ||
            value == PairingRtcState.disconnected) {
          unawaited(
            _handleRuntimeFailure('انقطع اتصال WebRTC مع جهاز الاستقبال.'),
          );
        }
      });

      emit(
        SenderPairingState(
          status: SenderPairingStatus.startingStream,
          peerName: payload.peerName,
        ),
      );

      await _startStreaming(payload.peerName);
    } on TimeoutException {
      emit(
        const SenderPairingState(
          status: SenderPairingStatus.failure,
          errorMessage:
              'انتهت مهلة الاتصال. تأكد أن الجهازين على نفس الشبكة وأن التلفزيون ما زال على شاشة الاستقبال.',
        ),
      );
    } catch (error) {
      emit(
        SenderPairingState(
          status: SenderPairingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      await rtcSession?.dispose();
      await client?.dispose();
    }
  }

  Future<void> retryStreaming() async {
    final String? peerName = state.peerName;
    if (_rtcSession == null || peerName == null) {
      emit(const SenderPairingState());
      return;
    }

    emit(
      SenderPairingState(
        status: SenderPairingStatus.startingStream,
        peerName: peerName,
      ),
    );

    try {
      await _startStreaming(peerName);
    } catch (error) {
      emit(
        SenderPairingState(
          status: SenderPairingStatus.failure,
          peerName: peerName,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _startStreaming(String peerName) async {
    await _projectionSession.requestAndStart();
    await _encoder.start(StreamingProfile.balanced);
    await _rtcSession!.startVideoSender(_encoder.packets);

    await _projectionInterruptionSubscription?.cancel();
    _projectionInterruptionSubscription = _projectionSession.interruptions
        .listen(
          (_) => unawaited(
            _handleRuntimeFailure('تم إيقاف إذن مشاركة الشاشة من النظام.'),
          ),
        );

    emit(
      SenderPairingState(
        status: SenderPairingStatus.streaming,
        peerName: peerName,
      ),
    );
  }

  Future<void> _handleRuntimeFailure(String message) async {
    await _stopCaptureOnly();
    if (!isClosed) {
      emit(
        SenderPairingState(
          status: SenderPairingStatus.failure,
          peerName: state.peerName,
          errorMessage: message,
        ),
      );
    }
  }

  Future<void> reset() async {
    await _disposeActiveSession();
    emit(const SenderPairingState());
  }

  Future<void> _stopCaptureOnly() async {
    await _projectionInterruptionSubscription?.cancel();
    _projectionInterruptionSubscription = null;
    await _encoder.stop();
    await _projectionSession.stop();
  }

  Future<void> _disposeActiveSession() async {
    await _rtcStateSubscription?.cancel();
    _rtcStateSubscription = null;
    await _stopCaptureOnly();
    await _rtcSession?.dispose();
    _rtcSession = null;
    await _client?.dispose();
    _client = null;
  }

  @override
  Future<void> close() async {
    await _disposeActiveSession();
    await _projectionSession.dispose();
    return super.close();
  }
}
