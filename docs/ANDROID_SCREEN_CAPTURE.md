# Android screen capture

CastFlow starts Android screen sharing in two coordinated layers.

## Foreground execution

A native Android foreground service is started through the `castflow/screen_capture` MethodChannel before capture begins.

The service uses the `mediaProjection` foreground-service type declared in the manifest and shows a persistent notification while mirroring is active.

## Capture

For Android 13 and lower, Flutter obtains the display `MediaStream` through `flutter_webrtc`'s `getDisplayMedia()` API while CastFlow runs a media-projection foreground service.

Android 14+ changes the required ordering: the user must grant the MediaProjection capture request before the media-projection foreground service is created. The current flutter_webrtc `getDisplayMedia()` flow does not expose a callback between consent and native capture startup, so CastFlow explicitly blocks this legacy path on API 34+ instead of allowing a runtime `SecurityException`.

The production Android 14+ path therefore requires CastFlow's own native MediaProjection handoff and capture integration. This is the next capture-layer increment.

On supported API levels, the stream is validated to contain at least one video track.

## Cleanup

Stopping capture:

1. stops every media track
2. disposes the MediaStream
3. stops the Android foreground service

Capture is never started silently. Android's system-level capture approval remains authoritative.

## Next

1. Replace the guarded Android 14+ path with a native MediaProjection consent -> foreground-service -> capture handoff.
2. Keep the existing WebRTC sender tuning layer for bitrate and frame-rate adaptation.
3. Synchronize capture resolution changes with the active ABR profile.
