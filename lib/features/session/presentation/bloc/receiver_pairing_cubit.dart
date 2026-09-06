import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pairing/pairing_qr_codec.dart';
import '../../data/pairing/pairing_rtc_session.dart';
import '../../data/signaling/local_signaling_server.dart';
import '../../domain/entities/handshake_payload.dart';

enum ReceiverPairingStatus { idle, starting, ready, connected, failure }

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
    PairingRtcSessionPort Function()? rtcSessionFactory,
  }) : _codec = codec,
       _random = secureRandom ?? Random.secure(),
       _rtcSessionFactory = rtcSessionFactory ?? PairingRtcSession.new,
       super(const ReceiverPairingState());

  final PairingQrCodec _codec;
  final Random _random;
  final PairingRtcSessionPort Function() _rtcSessionFactory;

  LocalSignalingServer? _server;
  PairingRtcSessionPort? _rtcSession;
  StreamSubscription<PairingRtcState>? _rtcStateSubscription;

  Future<void> start() async {
    if (state.status == ReceiverPairingStatus.starting ||
        state.status == ReceiverPairingStatus.ready ||
        state.status == ReceiverPairingStatus.connected) {
      return;
    }

    emit(
      state.copyWith(status: ReceiverPairingStatus.starting, clearError: true),
    );

    try {
      await _disposeRuntime();

      final String host = await _resolveLanIpv4();
      final String sessionId = _randomToken(18);
      final String token = _randomToken(32);
      final String peerId = _randomToken(12);

      final LocalSignalingServer server = LocalSignalingServer(
        sessionId: sessionId,
        token: token,
      );
      await server.start();

      final PairingRtcSessionPort rtcSession = _rtcSessionFactory();
      _rtcStateSubscription = rtcSession.states.listen((PairingRtcState value) {
        if (isClosed) {
          return;
        }
        switch (value) {
          case PairingRtcState.connected:
            emit(
              ReceiverPairingState(
                status: ReceiverPairingStatus.connected,
                qrData: state.qrData,
              ),
            );
            break;
          case PairingRtcState.failed:
          case PairingRtcState.disconnected:
            if (state.status == ReceiverPairingStatus.connected) {
              emit(
                ReceiverPairingState(
                  status: ReceiverPairingStatus.failure,
                  qrData: state.qrData,
                  errorMessage:
                      'انقطع اتصال WebRTC مع جهاز الإرسال. أعد المحاولة لإنشاء جلسة جديدة.',
                ),
              );
            }
            break;
          case PairingRtcState.idle:
          case PairingRtcState.connecting:
            break;
        }
      });
      await rtcSession.startReceiver(server);

      _server = server;
      _rtcSession = rtcSession;

      final int expiresAt =
          DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 5))
              .millisecondsSinceEpoch ~/
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
      await _disposeRuntime();
      emit(
        ReceiverPairingState(
          status: ReceiverPairingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    await _disposeRuntime();
    emit(const ReceiverPairingState());
  }

  Future<void> _disposeRuntime() async {
    await _rtcStateSubscription?.cancel();
    _rtcStateSubscription = null;
    await _rtcSession?.dispose();
    _rtcSession = null;
    await _server?.dispose();
    _server = null;
  }

  @override
  Future<void> close() async {
    await _disposeRuntime();
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

    final List<InternetAddress> candidates = <InternetAddress>[];
    for (final NetworkInterface interface in interfaces) {
      for (final InternetAddress address in interface.addresses) {
        if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
          candidates.add(address);
        }
      }
    }

    InternetAddress? preferred;
    for (final InternetAddress address in candidates) {
      if (_isPrivateLanAddress(address)) {
        preferred = address;
        break;
      }
    }

    final InternetAddress? selected =
        preferred ?? (candidates.isEmpty ? null : candidates.first);
    if (selected != null) {
      return selected.address;
    }

    throw StateError('No local IPv4 address is available for QR pairing.');
  }

  bool _isPrivateLanAddress(InternetAddress address) {
    final List<int> bytes = address.rawAddress;
    if (bytes.length != 4) {
      return false;
    }
    return bytes[0] == 10 ||
        (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
        (bytes[0] == 192 && bytes[1] == 168);
  }
}
