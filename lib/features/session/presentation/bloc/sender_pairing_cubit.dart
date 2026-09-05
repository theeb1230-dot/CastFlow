import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pairing/pairing_qr_codec.dart';
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
  SenderPairingCubit({PairingQrCodec codec = const PairingQrCodec()})
    : _codec = codec,
      super(const SenderPairingState());

  final PairingQrCodec _codec;
  LocalSignalingClient? _client;

  Future<void> pair(String qrData) async {
    if (state.status == SenderPairingStatus.connecting) {
      return;
    }

    emit(const SenderPairingState(status: SenderPairingStatus.connecting));

    try {
      final HandshakePayload payload = _codec.decode(qrData);
      final LocalSignalingClient client = LocalSignalingClient(
        host: payload.host,
        port: payload.port,
        sessionId: payload.sessionId,
        token: payload.token,
      );
      await client.connect();
      await _client?.dispose();
      _client = client;

      emit(
        SenderPairingState(
          status: SenderPairingStatus.paired,
          peerName: payload.peerName,
        ),
      );
    } catch (error) {
      emit(
        SenderPairingState(
          status: SenderPairingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> reset() async {
    await _client?.dispose();
    _client = null;
    emit(const SenderPairingState());
  }

  @override
  Future<void> close() async {
    await _client?.dispose();
    _client = null;
    return super.close();
  }
}
