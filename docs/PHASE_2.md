# Phase 2: Offline discovery and handshake

This phase establishes the local-only control plane before media transport.

## Implemented in this increment

- DNS-SD/mDNS discovery over `nsd`.
- Stable in-memory peer snapshots exposed as a stream.
- QR-safe pairing payload encoding and decoding.
- Validation for host, port, protocol version, expiry metadata, and session ID.

## Service type

CastFlow advertises and discovers:

`_castflow._tcp`

The service type intentionally stays within RFC-compliant DNS-SD naming rules.

## Security rules

- Pairing payloads are ephemeral.
- Pairing payloads do not contain durable credentials.
- Session identifiers must be regenerated per pairing attempt by the orchestration layer.
- An expired payload must be rejected by the consumer before establishing a WebRTC session.

## Next increment

Add local service registration, pairing-session orchestration, and WebRTC offer/answer exchange over the local control channel.
