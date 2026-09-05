import 'package:equatable/equatable.dart';

class StreamingProfile extends Equatable {
  const StreamingProfile({
    required this.width,
    required this.height,
    required this.framesPerSecond,
    required this.targetBitrateBps,
  });

  final int width;
  final int height;
  final int framesPerSecond;
  final int targetBitrateBps;

  static const StreamingProfile low = StreamingProfile(
    width: 1280,
    height: 720,
    framesPerSecond: 30,
    targetBitrateBps: 2500000,
  );

  static const StreamingProfile balanced = StreamingProfile(
    width: 1280,
    height: 720,
    framesPerSecond: 60,
    targetBitrateBps: 4500000,
  );

  static const StreamingProfile high = StreamingProfile(
    width: 1920,
    height: 1080,
    framesPerSecond: 30,
    targetBitrateBps: 6000000,
  );

  static const StreamingProfile ultra = StreamingProfile(
    width: 1920,
    height: 1080,
    framesPerSecond: 60,
    targetBitrateBps: 9000000,
  );

  @override
  List<Object> get props => <Object>[
    width,
    height,
    framesPerSecond,
    targetBitrateBps,
  ];
}
