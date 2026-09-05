# Android ABR capture synchronization

CastFlow now applies adaptive bitrate decisions to the native Android encoder and capture geometry, not just to WebRTC sender parameters.

## Behavior

The ABR controller selects among the existing streaming profiles.

When only bitrate changes while width, height and frame rate remain unchanged, the encoder can update bitrate live through `MediaCodec.PARAMETER_KEY_VIDEO_BITRATE`.

When width, height or frame rate changes, CastFlow restarts only the MediaCodec + VirtualDisplay encoder layer on the existing active MediaProjection session. The user is not asked for screen-capture consent again.

## Failure safety

A profile restart is transactional:

1. stop the current encoder
2. start the selected profile
3. if startup fails, attempt to restore the previously applied profile
4. keep the applied-profile state aligned with what is actually running

This prevents the ABR state machine from claiming a quality level that the native encoder failed to activate.

## Next

The next Android increment adds reconnect/session recovery and receiver-side interruption handling around the established capture, encoder and H.264 transport pipeline.
