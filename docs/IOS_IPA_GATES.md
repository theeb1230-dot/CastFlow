# iOS IPA qualification gates

CastFlow treats IPA creation, signing, provisioning, and installability as separate facts.

## Unsigned CI IPA

Pull-request CI builds the iPhoneOS Release app with `--no-codesign`, embeds the ReplayKit Broadcast Upload Extension, packages the resulting `Payload/Runner.app` directory as an IPA, validates the archive, and publishes it as an **unsigned** CI artifact.

The unsigned artifact is useful for structural verification only. It is not claimed to be directly installable on an iPhone and cannot satisfy Beta, Golden, or Complete installability gates.

The validator fails unless all of the following are true:

- `Payload/Runner.app` exists;
- `BroadcastUploadExtension.appex` is embedded under `PlugIns`;
- Runner bundle ID is `com.castflow.castflow`;
- extension bundle ID is `com.castflow.castflow.BroadcastUploadExtension`;
- app and extension versions both equal `1.0.0+1`;
- the extension declares `com.apple.broadcast-services-upload`;
- app and extension executables exist;
- neither app nor extension is code signed in unsigned mode;
- the IPA ZIP is non-empty and passes archive integrity verification;
- SHA-256 and build provenance are emitted alongside the IPA.

## Signed qualification

Signed validation is fail-closed. A signed IPA must contain valid embedded provisioning profiles for both Runner and the ReplayKit extension, pass strict `codesign` verification, and carry the shared App Group entitlement on both targets.

Repository CI does not fabricate Apple signing credentials. Golden and Complete qualification remain blocked until valid provisioning/signing material and physical-device installation evidence are available.
