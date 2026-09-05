import 'package:castflow/features/session/domain/entities/wifi_direct_peer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a native Wi-Fi Direct peer payload', () {
    final WifiDirectPeer peer = WifiDirectPeer.fromMap(
      const <Object?, Object?>{
        'name': 'Living Room TV',
        'address': '02:00:00:00:00:01',
        'status': 3,
        'primaryDeviceType': '10-0050F204-5',
        'secondaryDeviceType': null,
      },
    );

    expect(peer.name, 'Living Room TV');
    expect(peer.address, '02:00:00:00:00:01');
    expect(peer.status, 3);
  });

  test('rejects malformed native peer payloads', () {
    expect(
      () => WifiDirectPeer.fromMap(
        const <Object?, Object?>{'name': 'TV'},
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
