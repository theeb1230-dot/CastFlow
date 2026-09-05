import 'dart:convert';
import 'dart:io';

import '../../domain/entities/handshake_payload.dart';

class PairingQrCodec {
  const PairingQrCodec();

  static const String prefix = 'castflow:pair:';
  static const int supportedVersion = 1;
  static const int maximumPayloadCharacters = 2048;

  String encode(HandshakePayload payload) {
    final String json = jsonEncode(payload.toJson());
    final String encoded = base64UrlEncode(
      utf8.encode(json),
    ).replaceAll('=', '');
    return '$prefix$encoded';
  }

  HandshakePayload decode(String value, {DateTime? now}) {
    if (value.length > maximumPayloadCharacters || !value.startsWith(prefix)) {
      throw const FormatException('Invalid CastFlow pairing QR payload.');
    }

    final String encoded = value.substring(prefix.length);
    if (encoded.isEmpty) {
      throw const FormatException('CastFlow pairing payload is empty.');
    }

    final String padded = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('CastFlow pairing payload is malformed.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'CastFlow pairing payload must be an object.',
      );
    }

    final HandshakePayload payload;
    try {
      payload = HandshakePayload.fromJson(decoded);
    } catch (_) {
      throw const FormatException(
        'CastFlow pairing payload fields are invalid.',
      );
    }

    if (payload.version != supportedVersion ||
        payload.sessionId.isEmpty ||
        payload.sessionId.length > 128 ||
        payload.peerId.isEmpty ||
        payload.peerId.length > 128 ||
        payload.peerName.isEmpty ||
        payload.peerName.length > 128 ||
        payload.host.isEmpty ||
        payload.host.length > 255 ||
        !_isAllowedLocalIpv4(payload.host) ||
        payload.port < 1 ||
        payload.port > 65535 ||
        payload.token.length < 24 ||
        payload.token.length > 256) {
      throw const FormatException(
        'CastFlow pairing payload failed validation.',
      );
    }

    final int nowSeconds =
        (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000;
    if (payload.expiresAtEpochSeconds <= nowSeconds) {
      throw const FormatException('CastFlow pairing payload has expired.');
    }

    return payload;
  }

  bool _isAllowedLocalIpv4(String host) {
    final InternetAddress? address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv4) {
      return false;
    }

    final List<int> octets = address.rawAddress;
    if (octets.length != 4) {
      return false;
    }

    final int first = octets[0];
    final int second = octets[1];

    final bool private10 = first == 10;
    final bool private172 = first == 172 && second >= 16 && second <= 31;
    final bool private192 = first == 192 && second == 168;
    final bool linkLocal = first == 169 && second == 254;

    return private10 || private172 || private192 || linkLocal;
  }
}
