# Autonomous Development State

Last updated: 2026-09-07 23:20 Asia/Riyadh
Active PR: #32 `Fix sustained video rendering watchdog and publish 1.0.4+5`
Working branch: `fix-video-render-heartbeat-watchdog`
Current main head: `43c1dddceef42108770627562be8bfeb8e4d9f0c`
Base published runtime commit: `3f43a2e0b9983f4b4eec2dbb2828d898757f169f`
Current published version: `1.0.3+4`
Target version: `1.0.4+5`
Latest verified release: `v1.0.3-test.178`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Verified previous release
PR #31 merged successfully and its final pull-request CI run #177 was green.

GitHub prerelease:
- tag: `v1.0.3-test.178`
- source commit: `3f43a2e0b9983f4b4eec2dbb2828d898757f169f`
- version: `1.0.3+4`

Verified assets:
- `CastFlow-1.0.3+4-Android-Mobile.apk`
- `CastFlow-1.0.3+4-Android-TV.apk`
- `CastFlow-1.0.3+4-iOS-unsigned.ipa`
- `SHA256SUMS`
- `BUILD_PROVENANCE.txt`

The IPA is unsigned and is not claimed to be directly installable on a normal iPhone.

## Current run
- No PR was open at the beginning of this run.
- The highest-value runtime gap was persistent render health after the first-frame acknowledgement.
- PR #32 is now the only open PR.
- Added `videoHeartbeat` signaling.
- Android TV reports every successfully rendered decoder output separately from the one-time first-frame acknowledgement.
- Receiver pairing sends a heartbeat every 30 successfully rendered frames.
- Sender pairing starts a watchdog after first-frame readiness and stops capture if no render heartbeat is observed for more than five seconds.
- The watchdog is intended to detect a stalled receiver even when WebRTC itself remains connected.
- Added heartbeat signaling tests and ongoing rendered-frame callback coverage.
- Target release bumped to `1.0.4+5`.
- Release workflow targets only Android Mobile APK + Android TV APK + unsigned iOS IPA; AAB remains excluded.

## Release readiness
Formal grade: Developer Test only; not yet Experimental.

Evidence already achieved:
- first-frame readiness tied to actual Android TV MediaCodec output;
- green CI for 1.0.3+4;
- exact same-commit 1.0.3+4 APK/APK-TV/unsigned-IPA triplet;
- GitHub prerelease with SHA-256 and provenance.

Still missing for Experimental:
- physical Android phone -> Android TV visible-frame proof;
- sustained physical-TV rendering evidence;
- evidence that the primary physical-device runtime path opens and completes without crash;
- physical iOS ReplayKit runtime proof;
- signed/provisioned installable iOS IPA;
- reconnect/interruption/background device-matrix evidence.

## Release status for current change
- PR #32 must remain unmerged until all required checks are green and the branch is mergeable.
- Required new triplet after merge: Android Mobile APK + Android TV APK + iOS IPA version `1.0.4+5`.
- Same commit/version, SHA256SUMS and BUILD_PROVENANCE are mandatory.
- AAB must not be built or published.
- GitHub Release/Pre-Release must not be published if one of the three packages fails.

## أهداف التشغيل التالي
1. Resolve any remaining PR #32 merge/CI failures on the same branch only.
2. Verify formatting, analyze, full tests, stress/performance, Android release artifacts, iOS ReplayKit/IPA validation and triplet gate are all green.
3. Merge PR #32 only when it is mergeable and all required checks pass.
4. Verify main publishes the exact `1.0.4+5` Developer Test triplet under GitHub Releases.
5. Verify release assets, SHA256SUMS and BUILD_PROVENANCE match the main release commit.
6. Use physical Android phone -> Android TV testing to validate sustained visible rendering and collect user feedback.
7. Continue reconnect/interruption recovery and physical iOS evidence after the triplet is closed.
