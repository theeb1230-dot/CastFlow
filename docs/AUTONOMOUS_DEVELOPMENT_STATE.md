# Autonomous Development State

Last updated: 2026-09-07 15:20 Asia/Riyadh
Active PR: #31 `Fix first-frame runtime proof and publish 1.0.3+4`
Working branch: `fix-first-frame-runtime-ack`
Current head before this handoff update: `85bdfb96405e05d61e68e306f389ca92ce194ab3`
Base main: `1a8c63b79f2bc26ce6ce122c0b4d7044a3e3a92b`
Target version: `1.0.3+4`

## Source of truth
GitHub main, PR state, commits, workflow logs and Releases override this handoff when they differ.

## Current run
- PR #31 remains the only open PR and main remains at 1.0.2+3.
- Previous CI #156 on head 80ddbbe5 passed the full Android/iOS/triplet gates.
- Review found the first-frame proof was too weak: successful decoder input is not proof of rendered MediaCodec output.
- HardwareDecoderBridge now returns true only after a non-codec-config, non-EOS output buffer is released for rendering to the Surface.
- AndroidTvH264Renderer now propagates the native MediaCodec boolean render result. The remaining gap is consuming that result in the receiver pipeline through the typed renderer contract.
- Attempts to finish the Dart MethodChannel return-value wiring were blocked by the available write-safety layer during this run.
- Latest CI run #34121391873 on 85bdfb failed the formatting gate in android_tv_receiver_pipeline.dart before analyze/tests; iOS smoke continued independently.
- Do not merge PR #31 in this state and do not publish 1.0.3+4 from this head.

## Release readiness
Formal grade: Not yet Experimental.
Latest published Developer Test: v1.0.2-test.151.

Missing evidence:
- exact MediaCodec output result wired into Dart first-frame acknowledgement;
- green full CI/triplet on the corrected head;
- physical Android phone -> Android TV visible-frame proof;
- iOS physical ReplayKit runtime proof and signing/provisioning for installability;
- reconnect/interruption/background device-matrix evidence.

## Next-run objectives
1. Finish Dart wiring so videoReady is emitted only when HardwareDecoderBridge returns rendered=true.
2. Add regression tests: codec-config/input-only => no ack; first actual decoder output => exactly one ack; decoder failure => videoFailed.
3. Run dart format, analyze, unit/stress/performance gates and Android native compile.
4. Require Android Mobile APK + Android TV APK + unsigned iOS IPA triplet from the same corrected commit/version.
5. Merge PR #31 only after all required checks are green.
6. Verify the main push publishes 1.0.3+4 with SHA256SUMS and BUILD_PROVENANCE.
7. Then require physical-device visible-frame and persistence evidence before Experimental.
