import 'package:castflow/features/streaming/domain/services/android_screen_capture_runtime_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AndroidScreenCaptureRuntimePolicy policy =
      AndroidScreenCaptureRuntimePolicy();

  test(
    'allows legacy getDisplayMedia foreground-service flow through API 33',
    () {
      expect(policy.supportsLegacyGetDisplayMediaFlow(33), isTrue);
    },
  );

  test('blocks legacy flow on Android 14 and newer', () {
    expect(policy.supportsLegacyGetDisplayMediaFlow(34), isFalse);
    expect(policy.supportsLegacyGetDisplayMediaFlow(35), isFalse);
  });
}
