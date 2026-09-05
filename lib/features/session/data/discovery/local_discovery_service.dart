import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart';

import '../../domain/entities/cast_peer.dart';

class LocalDiscoveryService {
  static const String serviceType = '_castflow._tcp';

  Discovery? _discovery;
  Registration? _registration;

  final StreamController<List<CastPeer>> _peersController =
      StreamController<List<CastPeer>>.broadcast();
  final Map<String, CastPeer> _peers = <String, CastPeer>{};

  Stream<List<CastPeer>> get peers => _peersController.stream;

  Future<void> startDiscovery() async {
    if (_discovery != null) {
      return;
    }

    final Discovery discovery = await startDiscovery(
      serviceType,
      ipLookupType: IpLookupType.any,
    );
    discovery.addServiceListener(_handleService);
    _discovery = discovery;
  }

  Future<void> stopDiscovery() async {
    final Discovery? discovery = _discovery;
    if (discovery == null) {
      return;
    }
    await stopDiscovery(discovery);
    _discovery = null;
    _peers.clear();
    _emitPeers();
  }

  Future<void> advertise({
    required String name,
    required int port,
    required CastPeerPlatform platform,
    required String peerId,
  }) async {
    if (_registration != null) {
      return;
    }

    final Map<String, Uint8List?> txt = <String, Uint8List?>{
      'peerId': Uint8List.fromList(utf8.encode(peerId)),
      'platform': Uint8List.fromList(utf8.encode(platform.name)),
    };

    _registration = await register(
      Service(
        name: name,
        type: serviceType,
        port: port,
        txt: txt,
      ),
    );
  }

  Future<void> stopAdvertising() async {
    final Registration? registration = _registration;
    if (registration == null) {
      return;
    }
    await unregister(registration);
    _registration = null;
  }

  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    await _peersController.close();
  }

  void _handleService(Service service, ServiceStatus status) {
    final String? host = service.host;
    final int? port = service.port;
    final String name = service.name ?? 'CastFlow';

    if (host == null || port == null) {
      return;
    }

    final Map<String, String> txt = <String, String>{};
    service.txt?.forEach((String key, Uint8List? value) {
      if (value != null) {
        txt[key] = utf8.decode(value);
      }
    });

    final String peerId = txt['peerId'] ?? '$host:$port';
    if (status == ServiceStatus.lost) {
      _peers.remove(peerId);
      _emitPeers();
      return;
    }

    _peers[peerId] = CastPeer(
      id: peerId,
      name: name,
      host: host,
      port: port,
      platform: _parsePlatform(txt['platform']),
    );
    _emitPeers();
  }

  void _emitPeers() {
    final List<CastPeer> value = _peers.values.toList(growable: false)
      ..sort((CastPeer a, CastPeer b) => a.name.compareTo(b.name));
    _peersController.add(value);
  }

  CastPeerPlatform _parsePlatform(String? value) {
    return CastPeerPlatform.values.firstWhere(
      (CastPeerPlatform platform) => platform.name == value,
      orElse: () => CastPeerPlatform.unknown,
    );
  }
}
