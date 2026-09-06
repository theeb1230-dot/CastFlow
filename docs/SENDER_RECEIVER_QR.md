# Sender / Receiver QR pairing and casting

The QR code only exchanges short-lived LAN connection coordinates and credentials. A QR scan alone is never treated as a successful cast.

## Receiver flow

- starts the authenticated LAN signaling server;
- resolves a private LAN IPv4 address when available;
- initializes WebRTC and waits for a verified peer connection;
- leaves the QR screen only after `RTCPeerConnectionState.connected`;
- keeps the receiver session alive independently of the route lifecycle;
- attaches the CastFlow H.264 DataChannel receiver;
- renders incoming encoded packets through the Android TV MediaCodec texture pipeline;
- surfaces disconnect/failure instead of silently remaining paired.

## Sender flow

- scans and validates the QR payload;
- authenticates the local signaling channel;
- negotiates WebRTC SDP/ICE and verifies the peer reaches connected state;
- requests Android MediaProjection consent;
- starts the native VirtualDisplay + MediaCodec H.264 encoder;
- publishes encoded H.264 packets over the CastFlow WebRTC DataChannel;
- keeps the casting session alive when the user leaves the pairing page;
- stops capture only on explicit reset, runtime interruption, app disposal, or connection failure.

## Runtime qualification boundary

This addresses two physical-device failures observed on Android Mobile + Android TV:

1. the connection used to be destroyed when the sender left the pairing screen because the pairing Cubit was route-scoped;
2. a verified WebRTC connection did not automatically start screen capture or feed the TV decoder.

The session is now app-scoped and the Android sender/TV receiver media path is wired. Physical-device validation is still required before claiming Beta. iOS screen broadcasting remains subject to ReplayKit signing/provisioning and device testing.
