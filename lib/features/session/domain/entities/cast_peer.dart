import 'package:equatable/equatable.dart';

enum CastPeerPlatform { android, androidTv, ios, unknown }

class CastPeer extends Equatable {
  const CastPeer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.platform,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final CastPeerPlatform platform;

  @override
  List<Object?> get props => <Object?>[id, name, host, port, platform];
}
