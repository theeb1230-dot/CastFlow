import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pairing/pairing_qr_codec.dart';
import '../../data/pairing/pairing_rtc_session.dart';
import '../../data/signaling/local_signaling_client.dart';
import '../../domain/entities/handshake_payload.dart';

enum SenderPairingStatus { idle, connecting, paired, failure }

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
  }) : _codec = codec,
       _rtcSessionFactory = rtcSessionFactory ?? PairingRtcSession.new,
       super(const SenderPairingState());

  final PairingQrCodec _codec;
  final PairingRtcSessionPort Function() _rtcSessionFactory;

  LocalSignalingClient? _client;
  PairingRtcSessionPort? _rtcSession;

  Future<void> pair(String qrData) async {
    if (state.status == SenderPairingStatus.connecting) {
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

      emit(
        SenderPairingState(
          status: SenderPairingStatus.paired,
          peerName: payload.peerName,
        ),
      );
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

  Future<void> reset() async {
    await _disposeActiveSession();
    emit(const SenderPairingState());
  }

  Future<void> _disposeActiveSession() async {
    await _rtcSession?.dispose();
    _rtcSession = null;
    await _client?.dispose();
    _client = null;
  }

  @override
  Future<void> close() async {
    await _disposeActiveSession();
    return super.close();
  }
}
