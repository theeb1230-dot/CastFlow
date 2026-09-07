# Autonomous Development State

Last updated: 2026-09-07 23:16 Asia/Riyadh
Current main: `3f43a2e0b9983f4b4eec2dbb2828d898757f169f`
Current published version: `1.0.3+4`
Latest Release: `v1.0.3-test.178`
Working branch prepared for next increment: `fix-runtime-reconnect-recovery`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Completed this run
- PR #31 was the only open PR and is now merged.
- Merge commit on main: `3f43a2e0b9983f4b4eec2dbb2828d898757f169f`.
- First-frame proof now requires real Android TV MediaCodec output released to the Surface.
- Input-only or codec-config work does not produce a false video-ready acknowledgement.
- Renderer failures propagate to the receiver and sender startup fails closed when the first rendered frame is not confirmed.
- PR CI run #177 passed formatting, analyze, unit tests, stress/reconnect/resource gates, performance, Android native compile, Android release artifacts, iOS ReplayKit/unsigned IPA, and exact triplet gate.
- Main push CI run #178 passed the same gates and published the release.
- Published Developer Test Pre-Release: https://github.com/theeb1230-dot/CastFlow/releases/tag/v1.0.3-test.178
- Published assets are exactly:
  - `CastFlow-1.0.3+4-Android-Mobile.apk`
  - `CastFlow-1.0.3+4-Android-TV.apk`
  - `CastFlow-1.0.3+4-iOS-unsigned.ipa`
  - `SHA256SUMS`
  - `BUILD_PROVENANCE.txt`
- Release target is the main merge commit `3f43a2e0b9983f4b4eec2dbb2828d898757f169f`.
- No AAB was published.

## Release readiness
Formal grade remains Developer Test; not yet Experimental.

Evidence available:
- main CI green;
- Android Mobile release APK validated;
- Android TV release APK validated including package/version/Leanback gates;
- unsigned iOS IPA validated including Payload and ReplayKit extension;
- exact same-commit triplet gate passed;
- SHA256SUMS and BUILD_PROVENANCE were verified by the fail-closed publish job before Release creation.

Still missing for Experimental or higher:
- physical Android phone -> Android TV visible-frame proof;
- persistence proof beyond startup;
- physical reconnect/interruption recovery proof;
- physical iOS ReplayKit runtime proof;
- signed/provisioned installable iOS IPA.

## Blocker observed
The next code change targets runtime reconnect without rescanning QR. A branch named `fix-runtime-reconnect-recovery` was created from current main. The attempted networking/reconnect code mutation was blocked by the tool safety layer during this run. No reconnect code is claimed as applied. This did not affect the completed 1.0.3+4 release.

## أهداف التشغيل التالي
1. Re-check main, open PRs, CI and Release first; GitHub wins over this file if anything changed.
2. Continue on `fix-runtime-reconnect-recovery` only if no other PR is open.
3. Implement authenticated local-signaling reconnection plus WebRTC ICE restart/renegotiation without requesting a new QR when the existing session credentials remain valid.
4. Wire bounded reconnect recovery into sender runtime while keeping MediaProjection/encoder alive during transient transport loss; keep capture revocation as a separate user-consent-required failure.
5. Add tests for reconnect authentication, bounded retry/backoff, no overlapping recoveries, successful return to streaming, and exhaustion to a clear failure state.
6. Bump the next release-worthy version only when the reconnect implementation is complete and CI-ready, then update Android/iOS/triplet workflow parity.
7. Merge only after full green CI, then publish the next exact APK + APK-TV + unsigned IPA triplet from main.
8. Require physical Android phone -> Android TV visible-frame and reconnect persistence evidence before promoting beyond Developer Test.
