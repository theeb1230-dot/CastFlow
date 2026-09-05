# H.264 transport over WebRTC DataChannel

flutter_webrtc does not currently expose a first-class API for injecting app-produced encoded H.264 bytes as a normal MediaStreamTrack. CastFlow therefore transports the already hardware-encoded H.264 access units over a dedicated WebRTC DataChannel instead of decoding and re-encoding them.

## Why this preserves the low-latency goal

- MediaCodec remains the only encoder on Android.
- CastFlow does not decode the encoded access units on the sender.
- WebRTC still provides encrypted peer-to-peer SCTP/DTLS transport.
- No cloud relay or signaling server is introduced.

## Framing

Each H.264 access unit is split into chunks small enough for DataChannel transport. Every binary message includes:

- magic/version
- packet sequence
- chunk index/count
- presentation timestamp
- codec flags
- payload

The receiver reassembles chunks by sequence, including out-of-order arrivals.

## Backpressure

The transport checks DataChannel buffered bytes before enqueueing more data. If the buffer stays above the configured high-water mark beyond the timeout, sending fails explicitly rather than growing memory without bound.

## Receiver boundary

The reconstructed H.264 access units are ready for the Android receiver's MediaCodec decoder path. This is intentionally not presented as a standard WebRTC MediaStreamTrack; doing that with app-supplied encoded frames would require maintaining a flutter_webrtc native fork/custom source.

The next increment will connect this transport to sender/receiver session orchestration and then synchronize ABR with both encoder bitrate and capture resolution.
