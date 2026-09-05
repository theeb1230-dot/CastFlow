import '../../../session/domain/entities/connection_metrics.dart';
import '../entities/streaming_profile.dart';

class AdaptiveBitrateController {
  AdaptiveBitrateController({
    StreamingProfile initialProfile = StreamingProfile.balanced,
    this.degradeSampleThreshold = 2,
    this.upgradeSampleThreshold = 5,
    this.upgradeBitrateHeadroom = 1.35,
  }) : _currentProfile = initialProfile;

  final int degradeSampleThreshold;
  final int upgradeSampleThreshold;
  final double upgradeBitrateHeadroom;

  StreamingProfile _currentProfile;
  int _consecutiveDegradedSamples = 0;
  int _consecutiveHealthySamples = 0;

  StreamingProfile get currentProfile => _currentProfile;

  StreamingProfile ingest(ConnectionMetrics metrics) {
    if (_shouldDegrade(metrics)) {
      _consecutiveDegradedSamples += 1;
      _consecutiveHealthySamples = 0;

      if (_consecutiveDegradedSamples >= degradeSampleThreshold) {
        _currentProfile = _stepDown(_currentProfile);
        _consecutiveDegradedSamples = 0;
      }

      return _currentProfile;
    }

    if (_hasUpgradeHeadroom(metrics)) {
      _consecutiveHealthySamples += 1;
      _consecutiveDegradedSamples = 0;

      if (_consecutiveHealthySamples >= upgradeSampleThreshold) {
        _currentProfile = _stepUp(_currentProfile);
        _consecutiveHealthySamples = 0;
      }

      return _currentProfile;
    }

    _consecutiveDegradedSamples = 0;
    _consecutiveHealthySamples = 0;
    return _currentProfile;
  }

  bool _shouldDegrade(ConnectionMetrics metrics) {
    final double? availableBitrate = metrics.availableOutgoingBitrateBps;
    final bool bitrateStarved =
        availableBitrate != null &&
        availableBitrate < _currentProfile.targetBitrateBps * 0.9;

    return metrics.isDegraded || bitrateStarved;
  }

  bool _hasUpgradeHeadroom(ConnectionMetrics metrics) {
    if (metrics.isDegraded) {
      return false;
    }

    final StreamingProfile next = _stepUp(_currentProfile);
    if (next == _currentProfile) {
      return false;
    }

    final double? availableBitrate = metrics.availableOutgoingBitrateBps;
    if (availableBitrate == null) {
      return false;
    }

    final double required = next.targetBitrateBps * upgradeBitrateHeadroom;

    return availableBitrate >= required &&
        (metrics.roundTripTimeMs == null || metrics.roundTripTimeMs! < 80) &&
        (metrics.jitterMs == null || metrics.jitterMs! < 20) &&
        metrics.packetLossRate < 0.02;
  }

  StreamingProfile _stepDown(StreamingProfile profile) {
    return switch (profile.level) {
      StreamingProfileLevel.high => StreamingProfile.balanced,
      StreamingProfileLevel.balanced => StreamingProfile.low,
      StreamingProfileLevel.low => StreamingProfile.low,
    };
  }

  StreamingProfile _stepUp(StreamingProfile profile) {
    return switch (profile.level) {
      StreamingProfileLevel.low => StreamingProfile.balanced,
      StreamingProfileLevel.balanced => StreamingProfile.high,
      StreamingProfileLevel.high => StreamingProfile.high,
    };
  }
}
