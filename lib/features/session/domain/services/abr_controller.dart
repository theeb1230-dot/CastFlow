import '../entities/connection_metrics.dart';
import '../entities/streaming_profile.dart';
import 'adaptive_bitrate_policy.dart';

class AbrController {
  AbrController({
    AdaptiveBitratePolicy policy = const AdaptiveBitratePolicy(),
    int requiredStableSamples = 3,
    int requiredDegradedSamples = 2,
  }) : _policy = policy,
       _requiredStableSamples = requiredStableSamples,
       _requiredDegradedSamples = requiredDegradedSamples;

  final AdaptiveBitratePolicy _policy;
  final int _requiredStableSamples;
  final int _requiredDegradedSamples;

  StreamingProfile _current = StreamingProfile.balanced;
  StreamingProfile? _candidate;
  int _candidateCount = 0;

  StreamingProfile get current => _current;

  StreamingProfile update(ConnectionMetrics metrics) {
    final StreamingProfile desired = _policy.selectProfile(metrics);

    if (desired == _current) {
      _candidate = null;
      _candidateCount = 0;
      return _current;
    }

    if (_candidate != desired) {
      _candidate = desired;
      _candidateCount = 1;
      return _current;
    }

    _candidateCount += 1;

    final bool isUpgrade = desired.targetBitrateBps > _current.targetBitrateBps;
    final int threshold = isUpgrade
        ? _requiredStableSamples
        : _requiredDegradedSamples;

    if (_candidateCount >= threshold) {
      _current = desired;
      _candidate = null;
      _candidateCount = 0;
    }

    return _current;
  }

  void reset([StreamingProfile profile = StreamingProfile.balanced]) {
    _current = profile;
    _candidate = null;
    _candidateCount = 0;
  }
}
