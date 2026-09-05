import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../session/domain/entities/cast_peer.dart';
import '../../../session/domain/repositories/peer_discovery_service.dart';
import 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit(this._service) : super(const DiscoveryState());

  final PeerDiscoveryService _service;
  StreamSubscription<List<CastPeer>>? _subscription;

  Future<void> toggle() async {
    if (state.status == DiscoveryStatus.scanning) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (state.status == DiscoveryStatus.scanning) {
      return;
    }

    emit(state.copyWith(status: DiscoveryStatus.scanning, clearError: true));

    _subscription ??= _service.peers.listen(
      (List<CastPeer> peers) {
        emit(state.copyWith(peers: List<CastPeer>.unmodifiable(peers)));
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            status: DiscoveryStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );

    try {
      await _service.startDiscovery();
    } catch (error) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    try {
      await _service.stopDiscovery();
      emit(
        state.copyWith(
          status: DiscoveryStatus.idle,
          peers: const <CastPeer>[],
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _service.dispose();
    return super.close();
  }
}
