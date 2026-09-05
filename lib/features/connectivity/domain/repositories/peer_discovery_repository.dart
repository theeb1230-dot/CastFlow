import '../entities/discovered_peer.dart';

abstract interface class PeerDiscoveryRepository {
  Stream<List<DiscoveredPeer>> watchPeers();

  Future<void> start();

  Future<void> stop();
}
