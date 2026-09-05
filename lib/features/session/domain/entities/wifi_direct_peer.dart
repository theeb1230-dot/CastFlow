import 'package:equatable/equatable.dart';

class WifiDirectPeer extends Equatable {
  const WifiDirectPeer({
    required this.name,
    required this.address,
    required this.status,
    this.primaryDeviceType,
    this.secondaryDeviceType,
  });

  final String name;
  final String address;
  final int status;
  final String? primaryDeviceType;
  final String? secondaryDeviceType;

  factory WifiDirectPeer.fromMap(Map<Object?, Object?> map) {
    final Object? name = map['name'];
    final Object? address = map['address'];
    final Object? status = map['status'];

    if (name is! String || address is! String || status is! int) {
      throw const FormatException('Invalid Wi-Fi Direct peer payload.');
    }

    return WifiDirectPeer(
      name: name,
      address: address,
      status: status,
      primaryDeviceType: map['primaryDeviceType'] as String?,
      secondaryDeviceType: map['secondaryDeviceType'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    name,
    address,
    status,
    primaryDeviceType,
    secondaryDeviceType,
  ];
}
