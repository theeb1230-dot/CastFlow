import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/entities/connection_metrics.dart';

class WebRtcStatsParser {
  const WebRtcStatsParser();

  ConnectionMetrics parse(List<StatsReport> reports) {
    double? roundTripTimeSeconds;
    double? jitterSeconds;
    double? availableOutgoingBitrateBps;
    int bytesSent = 0;
    int bytesReceived = 0;
    int packetsLost = 0;
    int packetsReceived = 0;

    for (final StatsReport report in reports) {
      final Map<dynamic, dynamic> values = report.values;

      switch (report.type) {
        case 'candidate-pair':
          if (values['state'] == 'succeeded' ||
              values['selected'] == true ||
              values['nominated'] == true) {
            roundTripTimeSeconds ??= _asDouble(
              values['currentRoundTripTime'],
            );
            availableOutgoingBitrateBps ??= _asDouble(
              values['availableOutgoingBitrate'],
            );
          }
        case 'inbound-rtp':
          jitterSeconds ??= _asDouble(values['jitter']);
          packetsLost += _asInt(values['packetsLost']);
          packetsReceived += _asInt(values['packetsReceived']);
          bytesReceived += _asInt(values['bytesReceived']);
        case 'outbound-rtp':
          bytesSent += _asInt(values['bytesSent']);
      }
    }

    final int packetTotal = packetsReceived + packetsLost;
    final double packetLossRate = packetTotal <= 0
        ? 0
        : packetsLost / packetTotal;

    return ConnectionMetrics(
      roundTripTimeMs: roundTripTimeSeconds == null
          ? null
          : roundTripTimeSeconds * 1000,
      jitterMs: jitterSeconds == null ? null : jitterSeconds * 1000,
      packetLossRate: packetLossRate.clamp(0, 1).toDouble(),
      availableOutgoingBitrateBps: availableOutgoingBitrateBps,
      bytesSent: bytesSent,
      bytesReceived: bytesReceived,
      packetsLost: packetsLost,
      packetsReceived: packetsReceived,
    );
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  int _asInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
