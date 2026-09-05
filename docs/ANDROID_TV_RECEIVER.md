# Android TV receiver and rendering

CastFlow now has a native Android TV decode path for the H.264 packets transported by the existing low-latency WebRTC DataChannel session.

## Decode path

1. Encoded H.264 packets arrive through `EncodedVideoWebRtcSession.remotePackets`.
2. `AndroidTvReceiverPipeline` serializes packet submission so MediaCodec is never fed concurrently.
3. `HardwareDecoderBridge` configures an Android H.264 `MediaCodec` decoder.
4. The decoder renders directly to a Flutter-managed `SurfaceTexture`.
5. Flutter presents that surface through a `Texture` widget without a decode/re-encode cycle.

## Android TV focus

`AndroidTvReceiverSurface` uses a `FocusTraversalGroup`, an explicit `FocusNode`, focus visuals, and remote-friendly back/escape shortcuts. It is designed to be embedded by the final receiver flow once pairing/session orchestration is wired in the later UI milestone.

## Stage boundary

This slice deliberately does not duplicate the final sender/receiver navigation and QR pairing work targeted by the later interface milestone. It provides the runnable receiver rendering primitive and D-pad focus behavior that those screens consume.

## Failure handling

Decoder initialization and packet queue failures are surfaced instead of silently ignored. The receiver pipeline owns cleanup of its stream subscription and renderer resources.
