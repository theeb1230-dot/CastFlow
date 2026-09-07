# Autonomous Development State

Last updated: 2026-09-07 22:55 Asia/Riyadh
Active PR: #31 `Fix first-frame runtime proof and publish 1.0.3+4`
Working branch: `fix-first-frame-runtime-ack`
Current corrected head before this handoff update: `4a6ddc43176839096d67b1d35734e12fd0763ce3`
Base main version: `1.0.2+3`
Target version: `1.0.3+4`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Current run
- PR #31 is the only open PR.
- Earlier CI attempts exposed formatting/analyzer regressions and a deeper first-frame proof defect.
- The renderer contract now returns `Future<bool>` from `push()`.
- `HardwareDecoderBridge` returns true only when MediaCodec produced a non-codec-config, non-EOS output buffer that was released to the Surface.
- `AndroidTvH264Renderer` propagates that native rendered boolean.
- `AndroidTvReceiverPipeline` now acknowledges first-frame readiness only when the renderer returns `rendered == true`.
- Input-only decoder pushes return no acknowledgement.
- Renderer failures surface through `onRenderError` and the receiver sends `videoFailed`.
- Sender startup waits for `videoReady` or `videoFailed`; capture/encoder are stopped on startup failure or timeout.
- Regression coverage now includes: no ack for input-only decoder work, exactly one ack after the first rendered output, and no false ack on renderer failure.
- The receiver pipeline and its tests were fully rewritten after merge drift introduced literal escaped newline characters and an inconsistent fake renderer API.
- Version target remains `1.0.3+4`.
- Latest corrected CI is expected to run on the handoff-updated head; do not merge until all required jobs are green.

## Release readiness
Formal grade: Developer Test only; not yet Experimental.

Latest published Developer Test before this run: `v1.0.2-test.151`.

Required before publishing 1.0.3+4:
- full green analyze/test/stress/performance/native compile;
- validated Android Mobile APK and Android TV APK;
- validated unsigned iOS IPA with ReplayKit extension;
- exact same-commit triplet gate with SHA256SUMS and BUILD_PROVENANCE;
- main push publication workflow success.

Still missing for Experimental or higher:
- physical Android phone -> Android TV visible-frame proof;
- persistent rendering evidence beyond startup acknowledgement;
- physical iOS ReplayKit runtime proof;
- signed/provisioned installable iOS IPA;
- reconnect/interruption/background device-matrix evidence.

## أهداف التشغيل التالي
1. Finish PR #31 CI on the corrected first-frame implementation; fix any remaining failures on the same branch only.
2. Merge PR #31 only when analyze/tests/stress/performance/Android/iOS/triplet gates are all green.
3. Verify the main push publishes the exact `1.0.3+4` Developer Test triplet: Android Mobile APK + Android TV APK + unsigned iOS IPA.
4. Verify SHA256SUMS and BUILD_PROVENANCE match the main merge commit and release assets are downloadable.
5. Obtain or require physical Android phone -> Android TV visible-frame proof before promoting to Experimental.
6. After #31/release closure, continue with physical-device persistence, reconnect/interruption recovery, and iOS runtime/signing evidence.
