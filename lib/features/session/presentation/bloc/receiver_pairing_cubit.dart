import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pairing/pairing_qr_codec.dart';
import '../../data/signaling/local_signaling_server.dart';
import '../../domain/entities/handshake_payload.dart';

enum ReceiverPairingStatus { idle, starting, ready, failure }

class ReceiverPairingState extends Equatable {
  const ReceiverPairingState({
    this.status = ReceiverPairingStatus.idle,
    this.qrData,
    this.errorMessage,
  });

  final ReceiverPairingStatus status;
  final String? qrData;
  final String? errorMessage;

  ReceiverPairingState copyWith({
    ReceiverPairingStatus? status,
    String? qrData,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReceiverPairingState(
      status: status ?? this.status,
      qrData: qrData ?? this.qrData,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, qrData, errorMessage];
}

class ReceiverPairingCubit extends Cubit<ReceiverPairingState> {
  ReceiverPairingCubit({
    PairingQrCodec codec = const PairingQrCodec(),
    Random? secureRandom,
  }) : _codec = codec,
       _random = secureRandom ?? Random.secure(),
       super(const ReceiverPairingState());

  final PairingQrCodec _codec;
  final Random _random;
  LocalSignalingServer? _server;

  Future<void> start() async {
    if (state.status == ReceiverPairingStatus.starting ||
        state.status == ReceiverPairingStatus.ready) {
      return;
    }

    emit(state.copyWith(status: ReceiverPairingStatus.starting, clearError: true));

    try {
      final String host = await _resolveLanIpv4();
      final String sessionId = _randomToken(18);
      final String token = _randomToken(32);
      final String peerId = _randomToken(12);

      final LocalSignalingServer server = LocalSignalingServer(
        sessionId: sessionId,
        token: token,
      );
      await server.start();
      _server = server;

      final int expiresAt =
          DateTime.now().toUtc().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/
          1000;

      final HandshakePayload payload = HandshakePayload(
        version: PairingQrCodec.supportedVersion,
        sessionId: sessionId,
        peerId: peerId,
        peerName: Platform.isAndroid ? 'CastFlow Android' : 'CastFlow iOS',
        host: host,
        port: server.boundPort,
        expiresAtEpochSeconds: expiresAt,
        token: token,
      );

      emit(
        ReceiverPairingState(
          status: ReceiverPairingStatus.ready,
          qrData: _codec.encode(payload),
        ),
      );
    } catch (error) {
      await _server?.dispose();
      _server = null;
      emit(
        ReceiverPairingState(
          status: ReceiverPairingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    await _server?.dispose();
    _server = null;
    emit(const ReceiverPairingState());
  }

  @override
  Future<void> close() async {
    await _server?.dispose();
    _server = null;
    return super.close();
  }

  String _randomToken(int byteCount) {
    final List<int> bytes = List<int>.generate(
      byteCount,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _resolveLanIpv4() async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final NetworkInterface interface in interfaces) {
      for (final InternetAddress address in interface.addresses) {
        if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
          return address.address;
        }
      }
    }

    throw StateError('No local IPv4 address is available for QR pairing.');
  }
}
