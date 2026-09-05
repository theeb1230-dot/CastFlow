import 'package:castflow/features/streaming/domain/entities/screen_capture_config.dart';
import 'package:castflow/features/streaming/domain/entities/streaming_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds screen capture constraints from streaming profile', () {
    const ScreenCaptureConfig config = ScreenCaptureConfig(
      profile: StreamingProfile.high,
      includeAudio: false,
    );

    final Map<String, dynamic> constraints = config.toMediaConstraints();
    final Map<String, dynamic> video =
        constraints['video'] as Map<String, dynamic>;

    expect(constraints['audio'], isFalse);
    expect(
      (video['width'] as Map<String, int>)['ideal'],
      StreamingProfile.high.width,
    );
    expect(
      (video['height'] as Map<String, int>)['ideal'],
      StreamingProfile.high.height,
    );
    expect(
      (video['frameRate'] as Map<String, int>)['ideal'],
      StreamingProfile.high.framesPerSecond,
    );
  });
}
