import 'package:castflow/features/session/data/signaling/signaling_codec.dart';
import 'package:castflow/features/session/domain/entities/signaling_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SignalingCodec codec = SignalingCodec();

  test('round-trips an ICE signaling message', () {
    const SignalingMessage message = SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      sessionId: 'session-1',
      token: 'token-1',
      payload: <String, Object?>{
        'candidate': 'candidate:1 1 UDP 1 192.168.1.10 5000 typ host',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      },
    );

    expect(codec.decode(codec.encode(message)), message);
  });

  test('rejects unsupported signaling message type', () {
    expect(
      () =>
          codec.decode('{"type":"mystery","sid":"s","token":"t","payload":{}}'),
      throwsA(isA<FormatException>()),
    );
  });
}
