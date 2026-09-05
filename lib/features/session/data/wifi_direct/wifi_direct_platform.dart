import 'package:flutter/services.dart';

import '../../domain/entities/wifi_direct_peer.dart';

class WifiDirectPlatform {
  const WifiDirectPlatform({
    MethodChannel channel = const MethodChannel('castflow/wifi_direct'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  Future<void> discoverPeers() {
    return _channel.invokeMethod<void>('discoverPeers');
  }

  Future<List<WifiDirectPeer>> getPeers() async {
    final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
      'getPeers',
    );

    if (raw == null) {
      return const <WifiDirectPeer>[];
    }

    return raw
        .map((Object? value) {
          if (value is! Map<Object?, Object?>) {
            throw const FormatException('Invalid Wi-Fi Direct peer list.');
          }
          return WifiDirectPeer.fromMap(value);
        })
        .toList(growable: false);
  }

  Future<void> connect(String deviceAddress) {
    return _channel.invokeMethod<void>('connect', <String, Object?>{
      'deviceAddress': deviceAddress,
    });
  }

  Future<void> createGroup() {
    return _channel.invokeMethod<void>('createGroup');
  }

  Future<void> removeGroup() {
    return _channel.invokeMethod<void>('removeGroup');
  }

  Future<Map<Object?, Object?>> getConnectionInfo() async {
    final Map<Object?, Object?>? info = await _channel
        .invokeMethod<Map<Object?, Object?>>('getConnectionInfo');
    return info ?? const <Object?, Object?>{};
  }
}
