import 'package:castflow/features/session/data/handshake/handshake_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const HandshakeCodec codec = HandshakeCodec();

  test('round-trips a live offline pairing payload', () {
    final payload = codec.create(
      sessionId: 'session-1',
      peerId: 'peer-1',
      peerName: 'Living Room TV',
      host: '192.168.1.20',
      port: 45670,
      ttl: const Duration(minutes: 5),
    );

    final decoded = codec.decode(codec.encode(payload));

    expect(decoded, payload);
    expect(decoded.isExpired, isFalse);
  });

  test('rejects a non CastFlow QR payload', () {
    expect(
      () => codec.decode('https://example.com'),
      throwsA(isA<FormatException>()),
    );
  });
}
