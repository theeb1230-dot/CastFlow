# Phase 2 — Offline Networking Foundation

## Implemented
- CastFlow peer domain model.
- Short-lived QR handshake payloads using a local-only URI format.
- mDNS/NSD discovery and advertisement using `_castflow._tcp`.
- WebRTC peer orchestration with no public STUN/TURN servers.
- Local ICE candidate emission and offer/answer helpers.

## Offline model
CastFlow configures WebRTC with an empty ICE server list during local-only operation. Host candidates are exchanged through local signaling or QR-assisted pairing, keeping the media path independent of internet connectivity.

## QR handshake
QR payloads carry only short-lived connection bootstrap metadata:
- protocol version
- session id
- peer id/name
- LAN host/port
- expiry timestamp
- random ephemeral token

The token is not a durable credential and payloads expire quickly.

## Next slice
- Bind discovery results into BLoC.
- Add local signaling socket transport.
- Add Android Wi-Fi Direct adapter.
- Add platform permissions/manifests for Android/iOS.
- Add peer connection statistics needed by ABR.
