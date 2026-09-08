import 'package:castflow/features/session/domain/services/render_heartbeat_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderHeartbeatCadence', () {
    test('emits by elapsed rendered PTS instead of frame count', () {
      final RenderHeartbeatCadence cadence = RenderHeartbeatCadence();

      expect(cadence.registerRenderedFrame(0), isFalse);
      expect(cadence.registerRenderedFrame(500000), isFalse);
      expect(cadence.registerRenderedFrame(1000000), isTrue);
      expect(cadence.registerRenderedFrame(1500000), isFalse);
      expect(cadence.registerRenderedFrame(2000000), isTrue);
    });

    test('works at low frame rates without waiting for 30 frames', () {
      final RenderHeartbeatCadence cadence = RenderHeartbeatCadence();

      expect(cadence.registerRenderedFrame(0), isFalse);
      expect(cadence.registerRenderedFrame(1200000), isTrue);
      expect(cadence.registerRenderedFrame(2400000), isTrue);
    });

    test('resets baseline when presentation timestamp moves backwards', () {
      final RenderHeartbeatCadence cadence = RenderHeartbeatCadence();

      expect(cadence.registerRenderedFrame(5000000), isFalse);
      expect(cadence.registerRenderedFrame(6000000), isTrue);
      expect(cadence.registerRenderedFrame(100000), isFalse);
      expect(cadence.registerRenderedFrame(1100000), isTrue);
    });

    test('reset starts a fresh cadence window', () {
      final RenderHeartbeatCadence cadence = RenderHeartbeatCadence();

      expect(cadence.registerRenderedFrame(0), isFalse);
      expect(cadence.registerRenderedFrame(1000000), isTrue);
      cadence.reset();
      expect(cadence.registerRenderedFrame(9000000), isFalse);
    });
  });
}
