import 'dart:io';

import 'package:castflow/features/session/data/signaling/local_signaling_client.dart';
import 'package:castflow/features/session/data/signaling/local_signaling_server.dart';
import 'package:castflow/features/session/domain/entities/signaling_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exchanges signaling messages over loopback TCP', () async {
    final LocalSignalingServer server = LocalSignalingServer(
      sessionId: 'session-1',
      token: 'token-1',
      address: InternetAddress.loopbackIPv4,
    );
    await server.start();

    final LocalSignalingClient client = LocalSignalingClient(
      host: InternetAddress.loopbackIPv4.address,
      port: server.boundPort,
      sessionId: 'session-1',
      token: 'token-1',
    );
    await client.connect();

    final Future<SignalingMessage> received = server.messages.first;

    await client.send(
      SignalingMessageType.offer,
      const <String, Object?>{'sdp': 'v=0'},
    );

    final SignalingMessage message = await received.timeout(
      const Duration(seconds: 2),
    );

    expect(message.type, SignalingMessageType.offer);
    expect(message.payload['sdp'], 'v=0');

    await client.dispose();
    await server.dispose();
  });

  test('rejects client messages with wrong token', () async {
    final LocalSignalingServer server = LocalSignalingServer(
      sessionId: 'session-1',
      token: 'correct',
      address: InternetAddress.loopbackIPv4,
    );
    await server.start();

    final LocalSignalingClient client = LocalSignalingClient(
      host: InternetAddress.loopbackIPv4.address,
      port: server.boundPort,
      sessionId: 'session-1',
      token: 'wrong',
    );
    await client.connect();

    final Future<Object> error = server.messages.first.then<Object>(
      (SignalingMessage _) => StateError('Expected signaling rejection.'),
      onError: (Object value) => value,
    );

    await client.send(
      SignalingMessageType.offer,
      const <String, Object?>{'sdp': 'v=0'},
    );

    expect(
      await error.timeout(const Duration(seconds: 2)),
      isA<FormatException>(),
    );

    await client.dispose();
    await server.dispose();
  });
}
