import '../entities/cast_peer.dart';

abstract interface class PeerDiscoveryService {
  Stream<List<CastPeer>> get peers;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> dispose();
}
