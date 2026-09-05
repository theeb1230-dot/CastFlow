import 'package:flutter/services.dart';

enum ReplayKitLifecycleState {
  idle,
  started,
  paused,
  resumed,
  finished,
  encoderError,
  unknown,
}

class ReplayKitLifecycleSnapshot {
  const ReplayKitLifecycleSnapshot({
    required this.state,
    required this.lastHeartbeatSeconds,
    required this.videoSamples,
  });

  final ReplayKitLifecycleState state;
  final double lastHeartbeatSeconds;
  final int videoSamples;
}

class ReplayKitLifecycleEventDecoder {
  const ReplayKitLifecycleEventDecoder();

  ReplayKitLifecycleSnapshot decode(dynamic event) {
    if (event is! Map) {
      throw const FormatException('ReplayKit lifecycle event must be a map.');
    }

    final dynamic rawState = event['state'];
    final dynamic heartbeat = event['lastHeartbeat'];
    final dynamic videoSamples = event['videoSamples'];

    if (rawState is! String ||
        heartbeat is! num ||
        videoSamples is! int) {
      throw const FormatException('ReplayKit lifecycle event fields are invalid.');
    }

    return ReplayKitLifecycleSnapshot(
      state: _parseState(rawState),
      lastHeartbeatSeconds: heartbeat.toDouble(),
      videoSamples: videoSamples,
    );
  }

  ReplayKitLifecycleState _parseState(String state) {
    return switch (state) {
      'idle' => ReplayKitLifecycleState.idle,
      'started' => ReplayKitLifecycleState.started,
      'paused' => ReplayKitLifecycleState.paused,
      'resumed' => ReplayKitLifecycleState.resumed,
      'finished' => ReplayKitLifecycleState.finished,
      'encoder-error' => ReplayKitLifecycleState.encoderError,
      _ => ReplayKitLifecycleState.unknown,
    };
  }
}

class IosReplayKitLifecycleSource {
  IosReplayKitLifecycleSource({
    EventChannel eventChannel = const EventChannel(
      'castflow/replaykit_lifecycle/events',
    ),
    ReplayKitLifecycleEventDecoder decoder =
        const ReplayKitLifecycleEventDecoder(),
  }) : _eventChannel = eventChannel,
       _decoder = decoder;

  final EventChannel _eventChannel;
  final ReplayKitLifecycleEventDecoder _decoder;

  Stream<ReplayKitLifecycleSnapshot>? _snapshots;

  Stream<ReplayKitLifecycleSnapshot> get snapshots {
    return _snapshots ??= _eventChannel.receiveBroadcastStream().map(
      _decoder.decode,
    );
  }
}
