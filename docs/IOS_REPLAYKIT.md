# iOS ReplayKit broadcast upload extension

CastFlow uses a ReplayKit Broadcast Upload Extension for iOS screen capture instead of relying on unavailable NetworkExtension privileges.

## What this stage provides

- a real `RPBroadcastSampleHandler`
- lifecycle handling for start, pause, resume, finish
- ingestion of ReplayKit video/audio sample buffers
- an App Group shared by Runner and the extension
- heartbeat and sample-count state shared through `UserDefaults`
- deterministic Xcode target wiring through `tools/configure_replaykit.rb`
- CI compilation on a macOS runner without code signing

The sample handler intentionally does not perform H.264 compression in this stage. The next VideoToolbox stage consumes the video sample buffers and performs the encoding/transport integration. This stage still handles ReplayKit samples and lifecycle events at runtime; it does not contain placeholder methods or TODO stubs.

## Generated Xcode project

The repository currently regenerates iOS platform scaffolding with `flutter create`. After generation, run:

`ruby tools/configure_replaykit.rb`

The script is idempotent: it reuses the BroadcastUploadExtension target, source file, dependency, and Embed App Extensions phase when they already exist.

## Signing

Simulator CI builds run with no signing. Device distribution later requires valid provisioning for both:

- `com.castflow.castflow`
- `com.castflow.castflow.BroadcastUploadExtension`

Both targets must include the `group.com.castflow.shared` App Group capability. An unsigned build is not evidence of installability on a physical iPhone.
