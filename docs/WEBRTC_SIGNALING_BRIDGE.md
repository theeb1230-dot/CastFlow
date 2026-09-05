# WebRTC signaling bridge

The signaling bridge connects CastFlow's LAN-only signaling transport to the WebRTC peer orchestrator without leaking plugin-specific types across the application.

## Flow

1. Sender creates an SDP offer through `RtcSignalingPort`.
2. The bridge sends the offer through `SignalingTransport`.
3. Receiver accepts the offer and returns an SDP answer.
4. Local ICE candidates are forwarded automatically.
5. Remote ICE candidates are applied to the peer connection.
6. A `bye` message tears down bridge subscriptions.

## Boundary

`RtcSignalingAdapter` is the only layer that translates between JSON-safe maps and `flutter_webrtc` types such as `RTCSessionDescription` and `RTCIceCandidate`.

This keeps the domain and signaling transport testable without native WebRTC initialization.
