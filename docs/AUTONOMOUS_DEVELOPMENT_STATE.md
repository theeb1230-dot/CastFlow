# Autonomous Development State

Last updated: 2026-09-08 Asia/Riyadh
Active PR: pending creation from `fix-render-heartbeat-cadence`
Working branch: `fix-render-heartbeat-cadence`
Base main: `871a4a8723c081e5f86f899c4a6908cd13cd3900`
Base release: `1.0.4+5`
Target version: `1.0.5+6`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Current run
- Verified main at `871a4a8723c081e5f86f899c4a6908cd13cd3900`; Flutter CI run #192 is green.
- No PR was open at the start of this run.
- Found a false-stall risk: receiver heartbeat was emitted every 30 rendered frames while sender failed the stream after 5 seconds without a heartbeat. Low FPS could therefore stop a healthy stream.
- Fixed `RenderHeartbeatCadence` to anchor elapsed PTS to the last emitted heartbeat, not the previous frame. PTS rollback now resets the baseline without a false heartbeat.
- Wired the cadence into `ReceiverPairingCubit` and removed the `renderedFrames % 30` rule.
- Converted sender heartbeat liveness from wall-clock `DateTime.now()` to monotonic `Stopwatch`.
- Made runtime-failure handling idempotent so concurrent WebRTC/projection/heartbeat failures cannot run overlapping capture shutdowns.
- Added regression coverage for normal cadence, low FPS, PTS rollback, and explicit reset.
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
- new 1.0.5+6 PR CI and post-merge triplet release.

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
