# Autonomous Development State

Last updated: 2026-09-07 23:05 Asia/Riyadh
Active PR: #31 `Fix first-frame runtime proof and publish 1.0.3+4`
Working branch: `fix-first-frame-runtime-ack`
Validated code head before this handoff-only update: `660d545916ec8e234f1ea41c98de5f2c47319a8e`
Base main version: `1.0.2+3`
Target version: `1.0.3+4`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Current run
- PR #31 remains the only open PR.
- The first-frame proof defect is corrected end-to-end.
- `EncodedVideoRendererPort.push()` returns `Future<bool>`.
- `HardwareDecoderBridge` reports true only after MediaCodec emits a non-codec-config, non-EOS output buffer and releases it to the Surface for rendering.
- `AndroidTvH264Renderer` propagates the native rendered result.
- `AndroidTvReceiverPipeline` sends first-frame readiness exactly once, only after `rendered == true`; input-only decoder work produces no acknowledgement.
- Renderer failures propagate through `onRenderError` and receiver signaling sends `videoFailed`.
- Sender startup waits for `videoReady` or `videoFailed` and stops MediaProjection/encoder on startup failure or timeout.
- Regression tests cover first rendered output, input-only decoder work, one-shot acknowledgement, and renderer failure without false readiness.
- Release target remains `1.0.3+4`.

## CI evidence
Workflow run #177 on `660d545916ec8e234f1ea41c98de5f2c47319a8e` completed successfully:
- formatting: PASS
- flutter analyze: PASS
- flutter test: PASS
- stress/reconnect/resource-bound tests: PASS
- performance regression gate: PASS
- Android native compile smoke: PASS
- Android Mobile + TV release builds: PASS
- Android artifact validation/signature/package/version/TV gates: PASS
- iOS ReplayKit simulator + unsigned iPhoneOS build: PASS
- IPA structure/version/ReplayKit validation: PASS
- exact same-commit APK + APK-TV + unsigned IPA triplet gate: PASS

Run: https://github.com/theeb1230-dot/CastFlow/actions/runs/34157112079

Because this handoff update changes the PR head, wait for the new CI run and require the same gates green before merge.

## Release readiness
Formal grade: Developer Test only; not yet Experimental.

Latest published Developer Test before PR #31: `v1.0.2-test.151`.

PR #31 may be merged only after the CI run for the final handoff-updated head is fully green. After merge, verify main push publishes exactly:
- Android Mobile APK
- Android TV APK
- iOS IPA marked UNSIGNED/no-codesign
- SHA256SUMS
- BUILD_PROVENANCE

Still missing for Experimental or higher:
- physical Android phone -> Android TV visible-frame proof;
- persistent rendering evidence beyond startup acknowledgement;
- physical iOS ReplayKit runtime proof;
- signed/provisioned installable iOS IPA;
- reconnect/interruption/background device-matrix evidence.

## أهداف التشغيل التالي
1. Verify final CI on the handoff-updated PR #31 head and fix any regression on this same branch only.
2. Merge PR #31 immediately when every required gate is green.
3. Verify the main push workflow publishes the exact `1.0.3+4` Developer Test triplet under GitHub Releases.
4. Verify Release assets, SHA256SUMS, BUILD_PROVENANCE, source commit and version parity.
5. Require physical Android phone -> Android TV visible-frame and persistence proof before promoting to Experimental.
6. After #31 and its Release are closed, continue with reconnect/interruption recovery and physical iOS ReplayKit/signing evidence.
