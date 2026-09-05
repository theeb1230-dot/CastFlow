import 'package:equatable/equatable.dart';

class DiscoveredPeer extends Equatable {
  const DiscoveredPeer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.serviceType,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String serviceType;

  @override
  List<Object> get props => <Object>[id, name, host, port, serviceType];
}
