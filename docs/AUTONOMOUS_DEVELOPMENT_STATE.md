# Autonomous Development State

Last updated: 2026-09-07
Working branch: `fix-first-frame-runtime-ack`
Base main commit: `1a8c63b79f2bc26ce6ce122c0b4d7044a3e3a92b`
Target version: `1.0.3+4`

## Source of truth

This document is a handoff aid only. GitHub main/branches/PRs/CI/logs/releases are authoritative when they differ from this file.

## Current release readiness

Current published Developer Test: `v1.0.2-test.151` from commit `1a8c63b79f2bc26ce6ce122c0b4d7044a3e3a92b`.

Current formal grade: **Not yet Experimental**.

Evidence already established:
- Android Mobile and Android TV installable test APKs are produced from the same commit/version.
- Android TV physical-device launch and QR pairing were exercised by the user.
- A real WebRTC control connection between Android phone and Android TV was observed on physical devices.
- Flutter analyze/tests/stress/performance and Android/iOS packaging gates were green for 1.0.2+3.
- Unsigned iOS IPA is produced and structurally validated with embedded ReplayKit extension.

Missing for Experimental/Beta:
- physical evidence that Android MediaProjection video is actually rendered on Android TV;
- first-frame/runtime proof rather than connection-only success;
- iOS physical-device ReplayKit runtime validation and valid install signing for Beta or higher;
- full reconnect/interruption/background/device matrix evidence.

## Current defects being fixed

1. Sender previously marked the session as streaming immediately after starting encoder/DataChannel, without receiver proof that video reached MediaCodec.
2. Android TV receiver pipeline swallowed renderer failures and exposed no first-frame readiness signal.
3. If video startup failed after MediaProjection/encoder start, capture resources could remain active.
4. This handoff file did not previously exist.

## Current implementation

The active branch introduces:
- signaling events `videoReady` and `videoFailed`;
- sender waits for a receiver first-frame acknowledgement before entering `streaming`;
- Android TV pipeline reports the first successful renderer push exactly once;
- decoder/render errors are surfaced back to the sender;
- startup failure stops encoder and MediaProjection before reporting failure;
- version bumped to 1.0.3+4;
- triplet release workflow updated for Android Mobile APK + Android TV APK + unsigned iOS IPA.

## Release rules

No GitHub Release may be published unless all three artifacts are produced from the same commit/version and the triplet gate passes:
- Android Mobile APK
- Android TV APK
- iOS IPA

Unsigned IPA must remain explicitly marked UNSIGNED and not directly installable.

## Next-run objectives

1. Finish CI for the current first-frame acknowledgement PR and fix any failures on the same branch.
2. Merge only when required checks are green and the PR is mergeable.
3. Confirm the main push builds and publishes the 1.0.3+4 three-artifact Developer Test Release.
4. Ask for/consume physical-device feedback proving whether the phone screen actually appears on Android TV and whether leaving the sender page keeps casting alive.
5. If first-frame succeeds, instrument runtime frame counters/latency and connect them to RTT/jitter/packet-loss/ABR evidence.
6. Strengthen reconnect so the media DataChannel and first-frame gate recover after temporary Wi-Fi interruption without requiring a fresh QR scan.
7. Continue iOS ReplayKit sender integration/runtime readiness without claiming installability until signing/provisioning is valid.
