# Local signaling transport

CastFlow exchanges WebRTC control messages over a LAN-only TCP channel.

## Framing

Each signaling message is one UTF-8 JSON object terminated by a newline. The protocol carries:

- message type: offer, answer, ICE candidate, or bye
- session ID
- ephemeral pairing token
- message payload

## Authentication boundary

The session ID and random token originate from the short-lived QR handshake. The local signaling server validates both on every inbound message and closes a client that presents invalid credentials.

This is bootstrap authentication, not a substitute for WebRTC DTLS-SRTP. Media encryption remains WebRTC's responsibility.

## Offline behavior

No DNS, public STUN/TURN, cloud signaling, or internet endpoint is required for this transport. The client connects directly to the LAN host and port contained in the pairing payload.

## Next integration

The orchestration layer will map:

- SDP offer -> `SignalingMessageType.offer`
- SDP answer -> `SignalingMessageType.answer`
- local ICE candidates -> `SignalingMessageType.iceCandidate`

and feed received messages into `WebRtcOrchestrator`.
