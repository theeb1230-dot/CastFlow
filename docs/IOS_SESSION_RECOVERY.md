# iOS session recovery and background lifecycle

CastFlow reuses the same bounded SessionRecoveryController used on Android, but applies iOS-specific lifecycle rules instead of pretending the platforms behave identically.

## WebRTC reconnect

IosSessionRecoveryBinding listens to WebRTC peer-connection state.

- connected resets the retry counter
- disconnected/failed triggers bounded ICE restart while the app is foregrounded
- reconnect attempts are suppressed while the app is inactive, hidden, paused, or detached
- when the app resumes, a still-disconnected session triggers recovery

This avoids background reconnect loops that iOS may suspend or throttle.

## ReplayKit capture lifecycle

The Broadcast Upload Extension already writes shared ReplayKit state into the App Group. ReplayKitLifecycleBridge exposes those states to Flutter through an EventChannel.

- started/resumed means capture is active again
- finished or encoder-error marks capture permission/runtime interruption
- paused does not incorrectly request fresh capture consent

Transport recovery is blocked while capture is considered interrupted. A new ReplayKit started/resumed event clears that capture block.

## Limits

Simulator CI proves compilation and state-machine behavior only. Physical-device ReplayKit behavior, signed provisioning, interruption tests, and end-to-end sender/receiver validation remain required before Beta qualification.
