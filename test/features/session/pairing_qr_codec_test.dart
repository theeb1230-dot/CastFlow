import 'package:castflow/features/session/data/pairing/pairing_qr_codec.dart';
import 'package:castflow/features/session/domain/entities/handshake_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PairingQrCodec codec = PairingQrCodec();
  final DateTime now = DateTime.utc(2026, 9, 6, 1);

  HandshakePayload payload({int? expiresAtEpochSeconds}) {
    return HandshakePayload(
      version: PairingQrCodec.supportedVersion,
      sessionId: 'session-123',
      peerId: 'peer-123',
      peerName: 'Living Room TV',
      host: '192.168.1.20',
      port: 45678,
      expiresAtEpochSeconds:
          expiresAtEpochSeconds ??
          now.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      token: 'abcdefghijklmnopqrstuvwx12345678',
    );
  }

  test('round trips a valid offline pairing payload', () {
    final HandshakePayload expected = payload();
    final String encoded = codec.encode(expected);
    final HandshakePayload decoded = codec.decode(encoded, now: now);

    expect(encoded, startsWith(PairingQrCodec.prefix));
    expect(decoded, expected);
  });

  test('rejects expired pairing payloads', () {
    final String encoded = codec.encode(
      payload(
        expiresAtEpochSeconds:
            now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/
            1000,
      ),
    );

    expect(
      () => codec.decode(encoded, now: now),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects non CastFlow payloads', () {
    expect(
      () => codec.decode('https://example.com/not-castflow', now: now),
      throwsA(isA<FormatException>()),
    );
  });
}
