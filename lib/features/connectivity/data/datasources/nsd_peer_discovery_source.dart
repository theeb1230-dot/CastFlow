import 'dart:async';

import 'package:nsd/nsd.dart';

import '../../domain/entities/discovered_peer.dart';
import '../../domain/repositories/peer_discovery_repository.dart';

class NsdPeerDiscoverySource implements PeerDiscoveryRepository {
  NsdPeerDiscoverySource({
    this.serviceType = '_castflow._tcp',
  });

  final String serviceType;

  final Map<String, DiscoveredPeer> _peers = <String, DiscoveredPeer>{};
  final StreamController<List<DiscoveredPeer>> _controller =
      StreamController<List<DiscoveredPeer>>.broadcast();

  Discovery? _discovery;

  @override
  Stream<List<DiscoveredPeer>> watchPeers() => _controller.stream;

  @override
  Future<void> start() async {
    if (_discovery != null) {
      return;
    }

    final Discovery discovery = await startDiscovery(
      serviceType,
      autoResolve: true,
      ipLookupType: IpLookupType.any,
    );

    discovery.addServiceListener((Service service, ServiceStatus status) {
      final String? name = service.name;
      final String? host = service.host;
      final int? port = service.port;

      if (name == null || host == null || port == null) {
        return;
      }

      final String id = '$name@$host:$port';

      if (status == ServiceStatus.found) {
        _peers[id] = DiscoveredPeer(
          id: id,
          name: name,
          host: host,
          port: port,
          serviceType: service.type ?? serviceType,
        );
      } else if (status == ServiceStatus.lost) {
        _peers.remove(id);
      }

      _emitSnapshot();
    });

    _discovery = discovery;
  }

  @override
  Future<void> stop() async {
    final Discovery? discovery = _discovery;
    if (discovery == null) {
      return;
    }

    await stopDiscovery(discovery);
    _discovery = null;
    _peers.clear();
    _emitSnapshot();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _emitSnapshot() {
    final List<DiscoveredPeer> peers = _peers.values.toList()
      ..sort((DiscoveredPeer a, DiscoveredPeer b) => a.name.compareTo(b.name));
    if (!_controller.isClosed) {
      _controller.add(List<DiscoveredPeer>.unmodifiable(peers));
    }
  }
}
