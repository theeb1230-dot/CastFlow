import 'package:equatable/equatable.dart';

class ConnectionMetrics extends Equatable {
  const ConnectionMetrics({
    required this.roundTripTimeMs,
    required this.jitterMs,
    required this.packetLossRate,
    required this.availableOutgoingBitrateBps,
    required this.bytesSent,
    required this.bytesReceived,
    required this.packetsLost,
    required this.packetsReceived,
  });

  final double? roundTripTimeMs;
  final double? jitterMs;
  final double packetLossRate;
  final double? availableOutgoingBitrateBps;
  final int bytesSent;
  final int bytesReceived;
  final int packetsLost;
  final int packetsReceived;

  bool get isDegraded {
    final double? rtt = roundTripTimeMs;
    final double? jitter = jitterMs;
    return packetLossRate >= 0.05 ||
        (rtt != null && rtt >= 120) ||
        (jitter != null && jitter >= 30);
  }

  @override
  List<Object?> get props => <Object?>[
    roundTripTimeMs,
    jitterMs,
    packetLossRate,
    availableOutgoingBitrateBps,
    bytesSent,
    bytesReceived,
    packetsLost,
    packetsReceived,
  ];
}
