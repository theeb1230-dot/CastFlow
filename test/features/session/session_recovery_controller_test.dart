import 'package:castflow/features/session/domain/repositories/session_recovery_port.dart';
import 'package:castflow/features/session/domain/services/session_recovery_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecoveryPort implements SessionRecoveryPort {
  int restartCalls = 0;
  bool fail = false;

  @override
  Future<void> restartTransport() async {
    restartCalls += 1;
    if (fail) {
      throw StateError('restart failed');
    }
  }
}

void main() {
  test('restarts transport and resets attempts after recovery', () async {
    final _FakeRecoveryPort port = _FakeRecoveryPort();
    final List<Duration> sleeps = <Duration>[];
    final SessionRecoveryController controller = SessionRecoveryController(
      port: port,
      sleeper: (Duration duration) async => sleeps.add(duration),
    );

    await controller.onTransportLost();

    expect(controller.state, SessionRecoveryState.recovering);
    expect(controller.attempts, 1);
    expect(port.restartCalls, 1);
    expect(sleeps, isEmpty);

    controller.onTransportRecovered();

    expect(controller.state, SessionRecoveryState.connected);
    expect(controller.attempts, 0);
  });

  test('uses bounded backoff and stops after max attempts', () async {
    final _FakeRecoveryPort port = _FakeRecoveryPort();
    final List<Duration> sleeps = <Duration>[];
    final SessionRecoveryController controller = SessionRecoveryController(
      port: port,
      maxAttempts: 2,
      backoff: const <Duration>[Duration.zero, Duration(milliseconds: 250)],
      sleeper: (Duration duration) async => sleeps.add(duration),
    );

    await controller.onTransportLost();
    await controller.onTransportLost();
    final SessionRecoveryState state = await controller.onTransportLost();

    expect(state, SessionRecoveryState.exhausted);
    expect(port.restartCalls, 2);
    expect(sleeps, <Duration>[const Duration(milliseconds: 250)]);
  });

  test('capture interruption requires fresh user consent', () async {
    final _FakeRecoveryPort port = _FakeRecoveryPort();
    final SessionRecoveryController controller = SessionRecoveryController(
      port: port,
    );

    controller.onCaptureInterrupted();
    final SessionRecoveryState state = await controller.onTransportLost();

    expect(state, SessionRecoveryState.capturePermissionRequired);
    expect(port.restartCalls, 0);

    controller.resetAfterCaptureConsent();
    expect(controller.state, SessionRecoveryState.connected);
  });

  test(
    'failed restarts exhaust the controller at the configured limit',
    () async {
      final _FakeRecoveryPort port = _FakeRecoveryPort()..fail = true;
      final SessionRecoveryController controller = SessionRecoveryController(
        port: port,
        maxAttempts: 2,
        sleeper: (_) async {},
      );

      await expectLater(controller.onTransportLost(), throwsStateError);
      await expectLater(controller.onTransportLost(), throwsStateError);

      expect(controller.state, SessionRecoveryState.exhausted);
      expect(controller.attempts, 2);
    },
  );
}
