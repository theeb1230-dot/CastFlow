# Android session recovery

CastFlow now treats transport loss and capture loss as separate failure classes.

## WebRTC transport recovery

SessionRecoveryController performs bounded ICE restart attempts through a domain-level recovery port.

- first retry is immediate
- later retries use bounded backoff
- retries stop after the configured maximum
- a connected state clears the retry counter
- concurrent loss notifications do not start overlapping recovery attempts

This keeps reconnect behavior deterministic instead of allowing unbounded reconnect loops.

## MediaProjection interruption

Android can revoke or stop a MediaProjection session independently of WebRTC. The native MediaProjection.Callback.onStop() now reports onProjectionStopped to Flutter.

CastFlow deliberately does not request capture permission again in the background. A revoked projection moves recovery into capturePermissionRequired, where the user must explicitly grant screen capture again before streaming resumes.

That behavior is required for modern Android capture security and avoids pretending that an old MediaProjection token can be reused.

## Binding

AndroidSessionRecoveryBinding connects WebRTC connection state, MediaProjection interruption events, and the domain recovery controller.

The next Android TV increment can consume the same explicit recovery state when presenting receiver and focus UI.
