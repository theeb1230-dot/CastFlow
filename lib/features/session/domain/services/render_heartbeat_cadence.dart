class RenderHeartbeatCadence {
  RenderHeartbeatCadence({
    this.interval = const Duration(seconds: 1),
  }) : assert(interval > Duration.zero);

  final Duration interval;
  int? _lastPresentationTimeUs;

  bool registerRenderedFrame(int presentationTimeUs) {
    if (presentationTimeUs < 0) {
      throw ArgumentError.value(
        presentationTimeUs,
        'presentationTimeUs',
        'must be non-negative',
      );
    }

    final int? previous = _lastPresentationTimeUs;
    _lastPresentationTimeUs = presentationTimeUs;

    if (previous == null) {
      return false;
    }

    if (presentationTimeUs < previous) {
      return true;
    }

    return presentationTimeUs - previous >= interval.inMicroseconds;
  }

  void reset() {
    _lastPresentationTimeUs = null;
  }
}
