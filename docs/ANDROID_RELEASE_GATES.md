# Android release artifact gates

CastFlow produces distinct Android Mobile and Android TV artifacts from the same commit and Flutter version.

## Targets

- Mobile flavor: `com.castflow.castflow.mobile`, standard launcher only.
- TV flavor: `com.castflow.castflow.tv`, Leanback launcher and required Leanback feature.

Both release variants enable R8 code shrinking and Android resource shrinking. CI builds APK and AAB outputs for both flavors.

## CI signing scope

Pull-request CI uses the Flutter-generated debug keystore for release-build smoke validation so that `apksigner verify` can prove the APK is structurally signed and inspectable. This is not production signing and cannot qualify a Golden or Complete release.

Golden and Complete qualification require dedicated protected release signing material and must fail closed if it is unavailable.

## Static gates

CI verifies that:

- both Mobile and TV APKs exist and are non-empty;
- both Mobile and TV AABs exist and are non-empty;
- Mobile and TV application IDs are distinct and expected;
- versionName and versionCode are identical between both APKs;
- the Mobile APK exposes the standard launcher and does not expose Leanback launcher;
- the TV APK exposes Leanback launcher and declares the Leanback feature;
- both APK signatures pass `apksigner verify`;
- SHA-256 checksums are generated for all four Android artifacts.

These gates prove packaging integrity only. They do not substitute for physical-device installation, D-Pad navigation, MediaProjection capture, receiver rendering, or end-to-end casting evidence.
