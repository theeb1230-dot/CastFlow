# CastFlow Architecture

## Principles
CastFlow targets offline, peer-to-peer screen mirroring. "Zero latency" is not a physically valid guarantee, so the engineering target is ultra-low latency with observable metrics.

## Layers
- **Presentation**: Flutter widgets + BLoC/Cubit
- **Domain**: sessions, peers, transport capabilities, streaming policies
- **Data**: NSD/mDNS, WebRTC adapters, QR handshake
- **Platform**: Android MediaProjection/MediaCodec, iOS ReplayKit/VideoToolbox

## Connection flow
1. Discover peers over mDNS/NSD.
2. Exchange session metadata and capabilities.
3. Create local WebRTC PeerConnection.
4. Exchange SDP/ICE over local signaling.
5. Fall back to QR payload exchange when discovery/signaling fails.
6. Start screen capture only after explicit user authorization.
7. Continuously adapt bitrate/resolution/FPS from WebRTC stats.

## Security baseline
- No cloud signaling is required.
- Pairing sessions use short-lived identifiers.
- QR payloads must not contain durable credentials.
- Screen capture always depends on OS-level user consent.
