# Android VirtualDisplay + MediaCodec encoder

CastFlow now consumes an active native MediaProjection session with a hardware H.264 encoder surface.

## Pipeline

1. MediaProjection is already active through the Android 14-safe consent/FGS handoff.
2. CastFlow configures `MediaCodec` for H.264/AVC encoding.
3. The codec creates an input Surface.
4. MediaProjection creates a `VirtualDisplay` targeting that Surface.
5. A dedicated drain thread reads encoded output buffers.
6. Encoded packets are emitted to Flutter through `castflow/hardware_encoder/events`.

## Encoder controls

The encoder starts from a CastFlow `StreamingProfile`:

- width
- height
- frames per second
- target bitrate

Bitrate can be updated live through `MediaCodec.PARAMETER_KEY_VIDEO_BITRATE`, allowing ABR to tune the native encoder without rebuilding the whole capture session.

## Current boundary

This produces H.264 encoded access units but does not yet inject those bytes directly into the WebRTC native video pipeline. The next increment will choose the correct bridge strategy between the native encoder output and WebRTC transport while avoiding unnecessary decode/re-encode cycles.
