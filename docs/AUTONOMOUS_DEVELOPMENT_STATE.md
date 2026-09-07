# Autonomous Development State

Last updated: 2026-09-07
Active PR: #31 `Fix first-frame runtime proof and publish 1.0.3+4`
Working branch: `fix-first-frame-runtime-ack`
Base main commit: `1a8c63b79f2bc26ce6ce122c0b4d7044a3e3a92b`
PR head before this handoff update: `efebb5a07db4f50ca693e133a0033676ef46d98a`
Target version: `1.0.3+4`

## Source of truth

This document is a handoff aid only. GitHub main/branches/PRs/CI/logs/releases are authoritative when they differ from this file.

## Work completed in this run

- Reviewed main, all open PRs, branch inventory, recent commits, latest Releases, CI workflow and critical Android/iOS runtime files.
- Confirmed there were no open PRs at the start and the latest published triplet was `v1.0.2-test.151`.
- Found that the sender declared `streaming` before the Android TV receiver proved that any H.264 frame was successfully pushed into MediaCodec.
- Found that `AndroidTvReceiverPipeline` swallowed renderer errors.
- Found that video-start failure after MediaProjection/encoder startup could leave capture resources active.
- Added `videoReady` / `videoFailed` runtime signaling.
- Sender now waits for receiver first-frame proof before declaring streaming.
- TV acknowledges exactly once after the first successful renderer push and reports render failures.
- Startup failure now stops encoder and MediaProjection before surfacing the error.
- Added regression tests preventing false first-frame readiness.
- Added this persistent autonomous-development handoff file.
- Bumped release target to `1.0.3+4` and updated Android/iOS triplet validation and publishing workflow.

## PR / CI

PR #31 is the only open PR.

CI run #154 on head `efebb5a07db4f50ca693e133a0033676ef46d98a` passed:
- formatting;
- flutter analyze;
- flutter test;
- stress/reconnect/resource gates;
- performance regression gate;
- Android native compile;
- Android Mobile + Android TV release APK builds and validation;
- iOS ReplayKit/VideoToolbox simulator build;
- unsigned iPhoneOS app + IPA structure validation;
- exact APK + APK-TV + IPA triplet gate.

This documentation update creates a new head and therefore requires a fresh CI result before merge.

## Current release readiness

Current published Developer Test: `v1.0.2-test.151`.

Formal grade remains **Not yet Experimental** because physical-device video rendering has not yet been proven after the new first-frame gate.

Evidence established:
- Android TV physical installation/launch and QR pairing were exercised by the user.
- Real WebRTC control connection between Android phone and Android TV was observed on physical devices.
- CI packaging gates produce Android Mobile APK + Android TV APK + unsigned iOS IPA from one commit/version.
- ReplayKit extension is embedded and structurally validated in the unsigned IPA.

Still missing:
- physical evidence that MediaProjection frames actually appear on Android TV with 1.0.3+4;
- persistent casting after leaving the sender page verified on device;
- iOS physical-device ReplayKit runtime validation;
- signed/provisioned installable IPA for Beta or higher;
- complete reconnect/interruption/background/device matrix evidence.

## Release rules

No GitHub Release may be published unless Android Mobile APK + Android TV APK + iOS IPA are built from the same commit/version and the triplet gate passes. Unsigned IPA must remain explicitly marked UNSIGNED and not directly installable.

## Next-run objectives

1. If the fresh CI for this handoff commit is green, merge PR #31.
2. Verify the main push produces and publishes the exact `1.0.3+4` three-artifact Developer Test Release with SHA-256 and provenance.
3. Consume physical-device feedback for 1.0.3+4 and require proof that the phone screen appears on Android TV and stays active when the sender leaves the QR page.
4. If first-frame rendering succeeds, add receiver frame counters and end-to-end startup latency evidence and connect them to RTT/jitter/packet-loss/ABR telemetry.
5. Harden media reconnect so the video DataChannel and first-frame readiness gate recover after temporary Wi-Fi interruption without a fresh QR scan where feasible.
6. Continue iOS ReplayKit runtime sender integration and signing/provisioning readiness without claiming installability until it is actually valid.
7. Review dependency updates reported by CI and only adopt them when compatibility/tests prove no regression.
