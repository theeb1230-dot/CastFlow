# Android screen capture

CastFlow starts Android screen sharing in two coordinated layers.

## Foreground execution

A native Android foreground service is started through the `castflow/screen_capture` MethodChannel before capture begins.

The service uses the `mediaProjection` foreground-service type declared in the manifest and shows a persistent notification while mirroring is active.

## Capture

Flutter obtains the actual display `MediaStream` through `flutter_webrtc`'s `getDisplayMedia()` API.

On Android, this is the supported screen-capture path exposed by the WebRTC plugin and integrates with Android's system capture authorization flow.

The stream is validated to contain at least one video track.

## Cleanup

Stopping capture:

1. stops every media track
2. disposes the MediaStream
3. stops the Android foreground service

Capture is never started silently. Android's system-level capture approval remains authoritative.

## Next

Attach the capture stream to the peer connection and apply the current adaptive bitrate profile to the outbound sender.
