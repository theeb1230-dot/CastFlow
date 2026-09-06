# Sender / Receiver QR pairing

CastFlow uses the QR code only to exchange short-lived LAN connection coordinates and credentials. A QR scan by itself is **not** considered a successful pairing.

## Receiver flow

- starts the authenticated LAN signaling server;
- resolves a private LAN IPv4 address when available;
- initializes a WebRTC peer connection before displaying the QR code;
- publishes a five-minute pairing payload;
- processes SDP offer/answer and ICE candidates over the authenticated local signaling channel;
- leaves the QR screen only after `RTCPeerConnectionState.connected` is observed;
- reports disconnect/failure instead of silently remaining paired.

## Sender flow

- scans and validates the CastFlow QR payload;
- authenticates to the local signaling server;
- initializes WebRTC;
- creates a reliable CastFlow control DataChannel so ICE/DTLS negotiation must actually complete;
- exchanges SDP and ICE with the receiver;
- reports “connected” only after the peer connection reaches the connected state;
- fails with a visible timeout instead of reporting a false successful pair.

The control connection is local and does not require an internet service.

## Runtime qualification boundary

This fixes the false-positive pairing behavior observed on a physical phone/Android TV test, where the phone reported success while the TV remained on the QR screen.

A verified WebRTC control connection is still distinct from a proven end-to-end screen-casting session. MediaProjection/ReplayKit capture, encoded video transport, TV rendering, interruption recovery and real-device E2E evidence remain mandatory before Beta qualification.
