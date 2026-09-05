import 'dart:convert';

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

    test('rejects out-of-range port', () {
      final String encoded = base64Url.encode(
        utf8.encode(
          jsonEncode(<String, Object>{
            'v': 1,
            'sid': 'session-123',
            'host': '192.168.1.20',
            'port': 70000,
            'exp': DateTime.utc(2030).millisecondsSinceEpoch,
          }),
        ),
      );

      expect(
        () => PairingPayload.decode(encoded),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
