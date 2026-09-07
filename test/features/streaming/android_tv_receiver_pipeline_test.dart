import 'dart:async';
import 'dart:typed_data';

import 'package:castflow/features/streaming/data/decoder/android_tv_receiver_pipeline.dart';
import 'package:castflow/features/streaming/domain/entities/encoded_video_packet.dart';
import 'package:castflow/features/streaming/domain/repositories/encoded_video_renderer_port.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRenderer implements EncodedVideoRendererPort {
  _FakeRenderer({
    this.failPush = false,
    this.rendered = true,
    List<bool>? renderedResults,
  }) : _renderedResults = renderedResults ?? const <bool>[];

  final bool failPush;
  final bool rendered;
  final List<bool> _renderedResults;
  final List<int> pushed = <int>[];

  int _pushIndex = 0;
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
  Future<bool> push(EncodedVideoPacket packet) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (failPush) {
      throw StateError('decoder rejected frame');
    }

    pushed.add(packet.presentationTimeUs);
    if (_pushIndex < _renderedResults.length) {
      return _renderedResults[_pushIndex++];
    }

    _pushIndex += 1;
    return rendered;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _textureId = null;
  }
}

EncodedVideoPacket packet(int timestamp) {
  return EncodedVideoPacket(
    data: Uint8List.fromList(<int>[0, 0, 0, 1, 0x65, timestamp & 0xff]),
    presentationTimeUs: timestamp,
    flags: 0,
  );
}

void main() {
  test(
    'acknowledges exactly once after first rendered decoder output',
    () async {
      final _FakeRenderer renderer = _FakeRenderer(
        renderedResults: <bool>[false, true, true],
      );
      final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
        renderer: renderer,
      );
      final StreamController<EncodedVideoPacket> packets =
          StreamController<EncodedVideoPacket>();
      int firstFrameCallbacks = 0;

      final int textureId = await pipeline.start(
        packets: packets.stream,
        width: 1920,
        height: 1080,
        onFirstFrameRendered: () => firstFrameCallbacks += 1,
      );

      packets
        ..add(packet(1))
        ..add(packet(2))
        ..add(packet(3));

      await packets.close();
      await pipeline.stop();

      expect(textureId, 42);
      expect(renderer.pushed, <int>[1, 2, 3]);
      expect(firstFrameCallbacks, 1);
      expect(renderer.disposed, isTrue);
    },
  );

  test('reports continuity only for rendered decoder outputs', () async {
    final _FakeRenderer renderer = _FakeRenderer(
      renderedResults: <bool>[false, true, false, true],
    );
    final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
      renderer: renderer,
    );
    final StreamController<EncodedVideoPacket> packets =
        StreamController<EncodedVideoPacket>();
    final List<(int, int)> progress = <(int, int)>[];

    await pipeline.start(
      packets: packets.stream,
      width: 1920,
      height: 1080,
      onFrameRendered: (int renderedFrames, int presentationTimeUs) {
        progress.add((renderedFrames, presentationTimeUs));
      },
    );

    packets
      ..add(packet(10))
      ..add(packet(20))
      ..add(packet(30))
      ..add(packet(40));

    await packets.close();
    await pipeline.stop();

    expect(progress, <(int, int)>[(1, 20), (2, 40)]);
  });

  test(
    'does not ack when decoder accepts input but renders no output',
    () async {
      final _FakeRenderer renderer = _FakeRenderer(rendered: false);
      final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
        renderer: renderer,
      );
      final StreamController<EncodedVideoPacket> packets =
          StreamController<EncodedVideoPacket>();
      int firstFrameCallbacks = 0;

      await pipeline.start(
        packets: packets.stream,
        width: 1920,
        height: 1080,
        onFirstFrameRendered: () => firstFrameCallbacks += 1,
      );

      packets.add(packet(1));
      await packets.close();
      await pipeline.stop();

      expect(firstFrameCallbacks, 0);
      expect(renderer.pushed, <int>[1]);
    },
  );

  test('does not ack input-only decoder pushes', () async {
    final _FakeRenderer renderer = _FakeRenderer(
      renderedResults: <bool>[false, false],
    );
    final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
      renderer: renderer,
    );
    final StreamController<EncodedVideoPacket> packets =
        StreamController<EncodedVideoPacket>();
    int firstFrameCallbacks = 0;

    await pipeline.start(
      packets: packets.stream,
      width: 1920,
      height: 1080,
      onFirstFrameRendered: () => firstFrameCallbacks += 1,
    );

    packets
      ..add(packet(1))
      ..add(packet(2));
    await packets.close();
    await pipeline.stop();

    expect(firstFrameCallbacks, 0);
  });

  test('surfaces renderer failure without false first-frame ack', () async {
    final _FakeRenderer renderer = _FakeRenderer(failPush: true);
    final AndroidTvReceiverPipeline pipeline = AndroidTvReceiverPipeline(
      renderer: renderer,
    );
    final StreamController<EncodedVideoPacket> packets =
        StreamController<EncodedVideoPacket>();
    int firstFrameCallbacks = 0;
    final List<Object> errors = <Object>[];

    await pipeline.start(
      packets: packets.stream,
      width: 1920,
      height: 1080,
      onFirstFrameRendered: () => firstFrameCallbacks += 1,
      onRenderError: (Object error, StackTrace _) => errors.add(error),
    );

    packets.add(packet(1));
    await packets.close();
    await pipeline.stop();

    expect(firstFrameCallbacks, 0);
    expect(errors, hasLength(1));
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
