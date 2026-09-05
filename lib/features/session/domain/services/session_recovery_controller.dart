import '../repositories/session_recovery_port.dart';

enum SessionRecoveryState {
  connected,
  recovering,
  capturePermissionRequired,
  exhausted,
}

Future<void> _defaultRecoverySleep(Duration duration) {
  return Future<void>.delayed(duration);
}

class SessionRecoveryController {
  SessionRecoveryController({
    required SessionRecoveryPort port,
    this.maxAttempts = 3,
    List<Duration> backoff = const <Duration>[
      Duration.zero,
      Duration(milliseconds: 500),
      Duration(seconds: 2),
    ],
    Future<void> Function(Duration)? sleeper,
  }) : assert(maxAttempts > 0),
       _port = port,
       _backoff = List<Duration>.unmodifiable(backoff),
       _sleeper = sleeper ?? _defaultRecoverySleep;

  final SessionRecoveryPort _port;
  final int maxAttempts;
  final List<Duration> _backoff;
  final Future<void> Function(Duration) _sleeper;

  SessionRecoveryState _state = SessionRecoveryState.connected;
  int _attempts = 0;
  bool _inFlight = false;

  SessionRecoveryState get state => _state;
  int get attempts => _attempts;

  Future<SessionRecoveryState> onTransportLost() async {
    if (_state == SessionRecoveryState.capturePermissionRequired ||
        _state == SessionRecoveryState.exhausted ||
        _inFlight) {
      return _state;
    }

    if (_attempts >= maxAttempts) {
      _state = SessionRecoveryState.exhausted;
      return _state;
    }

    _inFlight = true;
    _state = SessionRecoveryState.recovering;

    try {
      final Duration delay = _delayForAttempt(_attempts);
      if (delay > Duration.zero) {
        await _sleeper(delay);
      }

      await _port.restartTransport();
      _attempts += 1;
    } catch (_) {
      _attempts += 1;
      if (_attempts >= maxAttempts) {
        _state = SessionRecoveryState.exhausted;
      }
      rethrow;
    } finally {
      _inFlight = false;
    }

    return _state;
  }

  void onTransportRecovered() {
    _attempts = 0;
    _state = SessionRecoveryState.connected;
  }

  void onCaptureInterrupted() {
    _state = SessionRecoveryState.capturePermissionRequired;
  }

  void resetAfterCaptureConsent() {
    _attempts = 0;
    _state = SessionRecoveryState.connected;
  }

  Duration _delayForAttempt(int attempt) {
    if (_backoff.isEmpty) {
      return Duration.zero;
    }
    final int index = attempt < _backoff.length ? attempt : _backoff.length - 1;
    return _backoff[index];
  }
}
