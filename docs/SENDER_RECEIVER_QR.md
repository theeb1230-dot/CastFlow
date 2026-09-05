# Sender / Receiver QR pairing

CastFlow now exposes runnable sender and receiver pairing surfaces from the dashboard.

## Receiver flow

- starts the existing LAN-only authenticated signaling server
- resolves a non-loopback IPv4 address
- generates cryptographically secure session credentials
- publishes a five-minute pairing payload as a QR code
- keeps signaling local to the LAN

## Sender flow

- scans the CastFlow QR code with the device camera
- validates the payload prefix, version, field sizes, port, token length, and expiry
- connects to the authenticated local signaling server
- reports pairing success only after the local TCP connection is established

The QR payload contains local connection coordinates and ephemeral credentials. It does not require internet access.

## Scope boundary

This stage removes the previous no-op Sender/Receiver buttons and establishes a real authenticated local pairing path. It does not yet claim that pressing the sender screen starts MediaProjection or ReplayKit casting automatically, nor that a physical-device cross-platform E2E casting matrix has passed. Those runtime orchestration and release gates remain required before Beta qualification.
