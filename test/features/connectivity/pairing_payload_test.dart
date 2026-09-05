import 'package:castflow/features/connectivity/domain/entities/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PairingPayload', () {
    test('round-trips through QR-safe encoding', () {
      final PairingPayload payload = PairingPayload(
        sessionId: 'session-123',
        host: '192.168.1.20',
        port: 45678,
        expiresAt: DateTime.utc(2030, 1, 1, 12),
        protocolVersion: 1,
      );

      final PairingPayload decoded = PairingPayload.decode(payload.encode());

      expect(decoded, payload);
    });

    test('rejects malformed payloads', () {
      expect(
        () => PairingPayload.decode('not-valid-base64'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid port', () {
      final String encoded = PairingPayload(
        sessionId: 'session-123',
        host: '192.168.1.20',
        port: 45678,
        expiresAt: DateTime.utc(2030),
        protocolVersion: 1,
      ).encode();

      final String tampered = encoded.replaceAll('A', 'B');

      expect(
        () => PairingPayload.decode(tampered),
        throwsA(anything),
      );
    });
  });
}
