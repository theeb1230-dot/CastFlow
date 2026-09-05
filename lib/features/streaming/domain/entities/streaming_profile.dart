import 'package:equatable/equatable.dart';

enum StreamingProfileLevel { low, balanced, high }

class StreamingProfile extends Equatable {
  const StreamingProfile({
    required this.level,
    required this.width,
    required this.height,
    required this.framesPerSecond,
    required this.targetBitrateBps,
  });

  final StreamingProfileLevel level;
  final int width;
  final int height;
  final int framesPerSecond;
  final int targetBitrateBps;

  static const StreamingProfile low = StreamingProfile(
    level: StreamingProfileLevel.low,
    width: 1280,
    height: 720,
    framesPerSecond: 30,
    targetBitrateBps: 2500000,
  );

  static const StreamingProfile balanced = StreamingProfile(
    level: StreamingProfileLevel.balanced,
    width: 1920,
    height: 1080,
    framesPerSecond: 30,
    targetBitrateBps: 5000000,
  );

  static const StreamingProfile high = StreamingProfile(
    level: StreamingProfileLevel.high,
    width: 1920,
    height: 1080,
    framesPerSecond: 60,
    targetBitrateBps: 8000000,
  );

  @override
  List<Object> get props => <Object>[
    level,
    width,
    height,
    framesPerSecond,
    targetBitrateBps,
  ];
}
