import '../entities/connection_metrics.dart';
import '../entities/streaming_profile.dart';

class AdaptiveBitratePolicy {
  const AdaptiveBitratePolicy();

  StreamingProfile selectProfile(ConnectionMetrics metrics) {
    final double loss = metrics.packetLossRate;
    final double? rtt = metrics.roundTripTimeMs;
    final double? jitter = metrics.jitterMs;
    final double? availableBitrate = metrics.availableOutgoingBitrateBps;

    if (loss >= 0.08 ||
        (rtt != null && rtt >= 180) ||
        (jitter != null && jitter >= 45) ||
        (availableBitrate != null && availableBitrate < 3000000)) {
      return StreamingProfile.low;
    }

    if (loss >= 0.04 ||
        (rtt != null && rtt >= 120) ||
        (jitter != null && jitter >= 30) ||
        (availableBitrate != null && availableBitrate < 5500000)) {
      return StreamingProfile.balanced;
    }

    if (loss >= 0.015 ||
        (rtt != null && rtt >= 70) ||
        (jitter != null && jitter >= 15) ||
        (availableBitrate != null && availableBitrate < 9500000)) {
      return StreamingProfile.high;
    }

    return StreamingProfile.ultra;
  }
}
