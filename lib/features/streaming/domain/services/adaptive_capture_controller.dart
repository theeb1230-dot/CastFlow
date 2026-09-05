import '../../../session/domain/entities/connection_metrics.dart';
import '../entities/streaming_profile.dart';
import '../repositories/streaming_encoder_port.dart';
import 'adaptive_bitrate_controller.dart';

class AdaptiveCaptureController {
  AdaptiveCaptureController({
    required StreamingEncoderPort encoder,
    AdaptiveBitrateController? abr,
  }) : _encoder = encoder,
       _abr = abr ?? AdaptiveBitrateController();

  final StreamingEncoderPort _encoder;
  final AdaptiveBitrateController _abr;

  StreamingProfile? _appliedProfile;

  StreamingProfile? get appliedProfile => _appliedProfile;

  Future<void> start() async {
    if (_appliedProfile != null) {
      return;
    }

    final StreamingProfile initial = _abr.currentProfile;
    await _encoder.start(initial);
    _appliedProfile = initial;
  }

  Future<StreamingProfile> ingest(ConnectionMetrics metrics) async {
    final StreamingProfile selected = _abr.ingest(metrics);
    final StreamingProfile? applied = _appliedProfile;

    if (applied == null) {
      await _encoder.start(selected);
      _appliedProfile = selected;
      return selected;
    }

    if (selected == applied) {
      return applied;
    }

    if (_requiresRestart(applied, selected)) {
      await _restartEncoder(previous: applied, next: selected);
    } else if (selected.targetBitrateBps != applied.targetBitrateBps) {
      await _encoder.setBitrate(selected.targetBitrateBps);
      _appliedProfile = selected;
    } else {
      _appliedProfile = selected;
    }

    return _appliedProfile!;
  }

  Future<void> stop() async {
    if (_appliedProfile == null) {
      return;
    }

    await _encoder.stop();
    _appliedProfile = null;
  }

  bool _requiresRestart(StreamingProfile current, StreamingProfile next) {
    return current.width != next.width ||
        current.height != next.height ||
        current.framesPerSecond != next.framesPerSecond;
  }

  Future<void> _restartEncoder({
    required StreamingProfile previous,
    required StreamingProfile next,
  }) async {
    await _encoder.stop();

    try {
      await _encoder.start(next);
      _appliedProfile = next;
    } catch (_) {
      try {
        await _encoder.start(previous);
        _appliedProfile = previous;
      } catch (_) {
        _appliedProfile = null;
      }
      rethrow;
    }
  }
}
