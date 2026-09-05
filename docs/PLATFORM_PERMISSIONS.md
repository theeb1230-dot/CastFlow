# Platform permissions

CastFlow uses platform permissions only for features the user explicitly invokes.

## Android

- `INTERNET`: required by Android networking APIs even when traffic stays on the LAN.
- `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`: inspect and manage local Wi-Fi state used by discovery and Wi-Fi Direct.
- `CHANGE_WIFI_MULTICAST_STATE`: required for reliable mDNS multicast reception on many Android devices.
- `NEARBY_WIFI_DEVICES`: modern Android permission used by nearby Wi-Fi features.
- `CAMERA`: QR pairing scanner.
- `RECORD_AUDIO`: optional audio capture only when enabled by the user.
- `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PROJECTION`: support long-running screen capture once MediaProjection is implemented in Phase 3.

Android TV is supported with `LEANBACK_LAUNCHER` and no hard touchscreen requirement.

## iOS

- `NSLocalNetworkUsageDescription`: local device discovery and signaling.
- `NSBonjourServices`: advertises/discovers `_castflow._tcp`.
- `NSCameraUsageDescription`: QR pairing.
- `NSMicrophoneUsageDescription`: optional user-enabled audio.

ReplayKit capture remains subject to Apple's system authorization and Broadcast Upload Extension model. CastFlow does not assume unrestricted hotspot creation or silent capture permissions.
