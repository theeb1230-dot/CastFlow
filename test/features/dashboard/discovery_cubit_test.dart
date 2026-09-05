import 'dart:async';

import 'package:castflow/features/dashboard/presentation/bloc/discovery_cubit.dart';
import 'package:castflow/features/dashboard/presentation/bloc/discovery_state.dart';
import 'package:castflow/features/session/domain/entities/cast_peer.dart';
import 'package:castflow/features/session/domain/repositories/peer_discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoveryService implements PeerDiscoveryService {
  final StreamController<List<CastPeer>> controller =
      StreamController<List<CastPeer>>.broadcast();

  bool started = false;
  bool stopped = false;

  @override
  Stream<List<CastPeer>> get peers => controller.stream;

  @override
  Future<void> startDiscovery() async {
    started = true;
  }

  @override
  Future<void> stopDiscovery() async {
    stopped = true;
  }

  @override
  Future<void> dispose() async {
    await controller.close();
  }
}

void main() {
  test('starts discovery, receives peers, then stops cleanly', () async {
    final _FakeDiscoveryService service = _FakeDiscoveryService();
    final DiscoveryCubit cubit = DiscoveryCubit(service);

    await cubit.start();

    expect(service.started, isTrue);
    expect(cubit.state.status, DiscoveryStatus.scanning);

    service.controller.add(const <CastPeer>[
      CastPeer(
        id: 'tv-1',
        name: 'Living Room TV',
        host: '192.168.1.30',
        port: 45670,
        platform: CastPeerPlatform.androidTv,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.peers, hasLength(1));
    expect(cubit.state.peers.single.name, 'Living Room TV');

    await cubit.stop();

    expect(service.stopped, isTrue);
    expect(cubit.state.status, DiscoveryStatus.idle);
    expect(cubit.state.peers, isEmpty);

    await cubit.close();
  });
}
