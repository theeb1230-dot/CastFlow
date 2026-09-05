import 'dart:async';

import 'package:castflow/features/streaming/data/decoder/android_tv_receiver_pipeline.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:castflow/features/streaming/domain/repositories/encoded_video_renderer_port.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRenderer implements EncodedVideoRendererPort {
  final List<int> pushed = <int>[];
  int? _textureId;
  bool disposed = false;

  @override
  int? get textureId => _textureId;

  @override
  Future<int> initialize({required int width, required int height}) async {
    expect(width, 1920);
    expect(height, 1080);
    _textureId = 42;
    return 42;
  }

  @override
  Future<void> push(EncodedVideoPacket packet) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    pushed.add(packet.presentationTimeUs);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _textureId = null;
  }
}

EncodedVideoPacket packet(int timestamp) {
  return EncodedVideoPacket(
    data: <int>[0, 0, 0, 1, 0x65, timestamp & 0xff],
    presentationTimeUs: timestamp,
    flags: 0,
  );
}

void main() {
  test('initializes renderer and serializes packet delivery', () async {
    final _FakeRenderer renderer = _FakeRenderer();
    final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
      renderer: renderer,
    );
    final StreamController<EncodedVideoPacket> packets =
        StreamController<EncodedVideoPacket>();

    final int textureId = await pipeline.start(
      packets: packets.stream,
      width: 1920,
      height: 1080,
    );

    packets
      ..add(packet(1))
      ..add(packet(2))
      ..add(packet(3));

    await packets.close();
    await pipeline.stop();

    expect(textureId, 42);
    expect(renderer.pushed, <int>[1, 2, 3]);
    expect(renderer.disposed, isTrue);
  });

  test('rejects a second start while active', () async {
    final _FakeRenderer renderer = _FakeRenderer();
    final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
      renderer: renderer,
    );
    final StreamController<EncodedVideoPacket> packets =
        StreamController<EncodedVideoPacket>();

    await pipeline.start(packets: packets.stream, width: 1920, height: 1080);

    await expectLater(
      pipeline.start(packets: packets.stream, width: 1920, height: 1080),
      throwsStateError,
    );

    await packets.close();
    await pipeline.dispose();
  });
}
