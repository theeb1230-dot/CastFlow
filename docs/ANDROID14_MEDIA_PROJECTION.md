# Android 14+ MediaProjection session handoff

CastFlow now implements the Android 14-safe MediaProjection session ordering natively.

## Required order

1. Launch the system screen-capture consent activity.
2. Wait for the user to grant capture permission.
3. Start the foreground service with `mediaProjection` type.
4. Call `MediaProjectionManager.getMediaProjection()`.
5. Keep the session active until CastFlow explicitly stops it or the platform revokes it.

This ordering avoids the `SecurityException` caused by creating the media-projection foreground service before capture consent on modern Android.

## Flutter API

`AndroidMediaProjectionSession` exposes:

- `requestAndStart()`
- `stop()`
- `isActive()`
- `sdkInt()`

The MethodChannel is:

`castflow/media_projection`

## Current boundary

This increment owns the permission and MediaProjection lifecycle. The next native capture increment consumes the active projection to create a VirtualDisplay and hardware-encoded video surface.

The existing flutter_webrtc `getDisplayMedia()` path remains guarded on API 34+ so CastFlow does not accidentally start two independent capture sessions.
