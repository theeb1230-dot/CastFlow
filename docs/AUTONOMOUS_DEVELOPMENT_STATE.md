# Autonomous Development State

Last updated: 2026-09-08 16:00 Asia/Riyadh
Active PR: #34 `fix-render-heartbeat-cadence`
Working branch: `fix-render-heartbeat-cadence`
Base main: `871a4a8723c081e5f86f899c4a6908cd13cd3900`
Base release: `1.0.4+5`
Target version: `1.0.5+6`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Current run
- Verified main at `871a4a8723c081e5f86f899c4a6908cd13cd3900`; Flutter CI run #192 is green.
- PR #34 is the single open PR for this run.
- Found a false-stall risk: receiver heartbeat was emitted every 30 rendered frames while sender failed the stream after 5 seconds without a heartbeat. Low FPS could therefore stop a healthy stream.
- Fixed `RenderHeartbeatCadence` to anchor elapsed PTS to the last emitted heartbeat, not the previous frame. PTS rollback now resets the baseline without a false heartbeat.
- Wired the cadence into `ReceiverPairingCubit` and removed the `renderedFrames % 30` rule.
- Converted sender heartbeat liveness from wall-clock `DateTime.now()` to monotonic `Stopwatch`.
- Made runtime-failure handling idempotent so concurrent WebRTC/projection/heartbeat failures cannot run overlapping capture shutdowns.
- Added regression coverage for normal cadence, low FPS, PTS rollback, and explicit reset.
- CI #193 exposed two concrete failures: stale iOS validator metadata and Dart formatting drift. The iOS validator was corrected to 1.0.5+6; CI #195 confirms iOS ReplayKit simulator build, unsigned iPhoneOS build, IPA validation, and artifact upload succeed.
- The previous formatter-only blocker in `receiver_pairing_cubit.dart` was resolved in commit `b13bb0618723d6092dbbd829827a9dcad9571280`; CI #197 confirms formatting, analyze, unit tests, stress/reconnect/resource-bound gates, and performance gate have passed so far. Android native/release validation and iOS ReplayKit jobs are still running, therefore no merge or release is allowed yet.
- Bumped application/release pipeline to `1.0.5+6`; any merged product change must publish a new exact Mobile APK + TV APK + unsigned IPA Developer Test triplet.
- Golden UX product direction remains: Android TV receiver-only auto-start QR; Android/iOS sender-only; QR zoom; direct-local media path with automatic transport negotiation; iOS ReplayKit with only unavoidable system consent.
- Quality/stability remain priority #1: no default cloud media relay, bounded latency, render continuity, ABR, reconnect and packet-loss resilience.

## Release readiness
Formal grade: Developer Test only; not yet Experimental.

Evidence already present:
- main CI #192 green for 1.0.4+5.
- Android Mobile/TV release builds and unsigned ReplayKit IPA pipeline exist with exact-triplet/version/provenance gates.
- WebRTC runtime pairing, video transport, Android TV decoder output and render continuity telemetry are implemented.

Still missing for Experimental:
- physical Android phone -> Android TV visible sustained rendering proof;
- physical-device app-open/runtime smoke;
- physical iOS ReplayKit runtime proof;
- reconnect/interruption/background device evidence;
- PR #34 CI is not fully green yet: CI #197 is in progress from head `b13bb0618723d6092dbbd829827a9dcad9571280`; formatting/analyze/unit/stress/performance are green, while Android build/validation and iOS ReplayKit completion remain pending.
- post-merge 1.0.5+6 triplet release.

## أهداف التشغيل التالي
1. Heartbeat reliability PR
   - Open exactly one PR from `fix-render-heartbeat-cadence`.
   - Run formatting, analyze, unit, stress and performance gates.
   - Fix every failure on the same PR until green.
   - Merge only when required checks and triplet gate are green.
2. 1.0.5+6 release
   - Verify Mobile APK package/version/signature.
   - Verify TV APK Leanback launcher/package/version/signature.
   - Verify unsigned IPA Payload/ReplayKit/version structure.
   - Require same commit/version and SHA-256/provenance.
   - Publish a new Developer Test prerelease after merge.
3. Android TV receiver-only boot
   - Make TV target enter receiver mode directly.
   - Auto-start local signaling/session bootstrap.
   - Show dynamic QR immediately with D-Pad-safe recovery controls.
   - Remove sender-mode navigation from TV user flow.
4. Mobile sender-only flow
   - Make Android/iOS targets enter sender pairing flow.
   - Remove receiver-mode navigation from phone UX.
   - Preserve system capture consent only when required.
   - Add reconnect without repeating unnecessary setup.
5. QR distance usability
   - Add pinch-to-zoom to scanner.
   - Add explicit zoom slider/buttons.
   - Add autofocus and torch controls.
   - Test long-distance QR framing and scanner lifecycle.
6. Secure QR bootstrap
   - Add short expiry and receiver capabilities/transport hints.
   - Add ephemeral session identity/fingerprint.
   - Add anti-replay validation.
   - Keep QR payload minimal and versioned.
7. Direct-local transport orchestrator
   - Prefer same-LAN direct WebRTC host/direct candidates.
   - Detect Android Wi-Fi Direct/Aware/local-only capabilities.
   - Add automatic fallback selection without technical menus.
   - Keep media off cloud relay whenever a local path is viable.
8. Routerless Android path
   - Evaluate TV LocalOnlyHotspot/SoftAP support through public APIs.
   - Encode temporary bootstrap data in QR when available.
   - Connect Android sender through supported network request APIs.
   - Preserve mandatory Android system confirmation rather than bypassing it.
9. iOS minimal-step casting
   - Keep pairing local and sender-only.
   - Integrate ReplayKit Broadcast Extension launch UX with minimum public-API steps.
   - Preserve unavoidable iOS consent/picker.
   - Test cellular-data-active plus local media path behavior.
10. Quality and stability gates
   - Add no-internet-but-local-stream regression scenario.
   - Add packet-loss/jitter/bandwidth-collapse ABR tests.
   - Add bounded-queue/latency accumulation checks.
   - Add TV restart/session reconnect and rotation tests.
   - Add sustained render/heartbeat soak coverage.

## Latest execution checkpoint
- GitHub source of truth checked at 2026-09-08 16:00 Asia/Riyadh.
- Main remains `871a4a8723c081e5f86f899c4a6908cd13cd3900` and PR #34 is the only open PR.
- Formatter fix commit: `b13bb0618723d6092dbbd829827a9dcad9571280`.
- CI run: #197 (`34229507685`). Formatting, analyze, unit, stress/reconnect/resource-bound, and performance gates passed at this checkpoint.
- `lib/app.dart` still routes every platform to `DashboardScreen`; receiver-only TV auto-entry and sender-only mobile/iOS remain the next product gap after this release closes.
- Formal readiness remains Developer Test; no device-matrix evidence was added in this execution.
