import 'package:equatable/equatable.dart';

import '../../../session/domain/entities/cast_peer.dart';

enum DiscoveryStatus { idle, scanning, failure }

class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.peers = const <CastPeer>[],
    this.errorMessage,
  });

  final DiscoveryStatus status;
  final List<CastPeer> peers;
  final String? errorMessage;

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<CastPeer>? peers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      peers: peers ?? this.peers,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, peers, errorMessage];
}
