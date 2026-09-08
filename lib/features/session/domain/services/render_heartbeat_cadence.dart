class RenderHeartbeatCadence {
  RenderHeartbeatCadence({
    this.interval = const Duration(seconds: 1),
  }) : assert(interval > Duration.zero);

  final Duration interval;
  int? _lastHeartbeatPresentationTimeUs;

  bool registerRenderedFrame(int presentationTimeUs) {
    if (presentationTimeUs < 0) {
      throw ArgumentError.value(
        presentationTimeUs,
        'presentationTimeUs',
        'must be non-negative',
      );
    }

    final int? baseline = _lastHeartbeatPresentationTimeUs;
    if (baseline == null) {
      _lastHeartbeatPresentationTimeUs = presentationTimeUs;
      return false;
    }

    if (presentationTimeUs < baseline) {
      _lastHeartbeatPresentationTimeUs = presentationTimeUs;
      return false;
    }

    if (presentationTimeUs - baseline < interval.inMicroseconds) {
      return false;
    }

    _lastHeartbeatPresentationTimeUs = presentationTimeUs;
    return true;
  }

  void reset() {
    _lastHeartbeatPresentationTimeUs = null;
  }
}
