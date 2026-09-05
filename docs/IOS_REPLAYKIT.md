# iOS ReplayKit broadcast upload extension

CastFlow uses a ReplayKit Broadcast Upload Extension for iOS screen capture instead of relying on unavailable NetworkExtension privileges.

## Current implementation

- real `RPBroadcastSampleHandler` lifecycle
- App Group shared by Runner and the Broadcast Upload Extension
- ReplayKit video sample ingestion
- real-time H.264 compression through VideoToolbox `VTCompressionSession`
- frame reordering disabled for latency
- keyframe SPS/PPS conversion to Annex-B
- bounded App Group spool for encoded H.264 access units
- deterministic Xcode target wiring through `tools/configure_replaykit.rb`
- macOS CI compilation without code signing

Encoded records in `encoded-video.bin` use a compact binary header:

- 8 bytes presentation timestamp in microseconds
- 4 bytes flags, bit 0 denotes keyframe
- 4 bytes H.264 payload length
- Annex-B H.264 payload

The spool is bounded and resets when it exceeds its configured size rather than growing without limit.

## WebRTC boundary

Android already transports application-produced H.264 access units over CastFlow's encrypted WebRTC DataChannel path without sender-side decode/re-encode. The iOS VideoToolbox output now reaches the same encoded-frame boundary, but the Runner-side App Group drain into that existing WebRTC publisher remains part of the unfinished iOS transport slice. This document therefore does not claim complete iOS WebRTC casting yet.

## Generated Xcode project

The repository currently regenerates iOS platform scaffolding with `flutter create`. After generation, run:

`ruby tools/configure_replaykit.rb`

The script is idempotent and wires both `SampleHandler.swift` and `VideoToolboxH264Encoder.swift` into the extension target.

## Signing

Simulator CI builds run with no signing. Device distribution later requires valid provisioning for both:

- `com.castflow.castflow`
- `com.castflow.castflow.BroadcastUploadExtension`

Both targets must include the `group.com.castflow.shared` App Group capability. An unsigned build is not evidence of installability on a physical iPhone.


## Runner drain into WebRTC

The Runner now registers `ReplayKitSpoolBridge` on the `castflow/replaykit_encoded/events` EventChannel. The bridge incrementally reads complete bounded records from the App Group spool, tolerates partial writes, resets safely after spool truncation, and publishes H.264 packets to Dart.

`IosReplayKitEncodedSource` converts those native events into `EncodedVideoPacket` objects. `EncodedVideoWebRtcSession` accepts that packet stream through `senderPackets`, so the same encrypted WebRTC DataChannel publisher used by Android can carry VideoToolbox output without decoding and re-encoding it.

This completes the encoded-data plumbing boundary for phase #21. It does not by itself prove a physical-device iOS broadcast session or complete sender UI orchestration. Those runtime/lifecycle and UI gates remain required before Beta qualification.
