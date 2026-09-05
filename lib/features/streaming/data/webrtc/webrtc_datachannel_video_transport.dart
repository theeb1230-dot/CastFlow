import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/repositories/binary_video_transport.dart';

class WebRtcDataChannelVideoTransport implements BinaryVideoTransport {
  WebRtcDataChannelVideoTransport(
    this._channel, {
    this.highWaterMarkBytes = 512 * 1024,
    this.lowWaterMarkBytes = 128 * 1024,
    this.backpressureTimeout = const Duration(seconds: 2),
  }) {
    _channel.bufferedAmountLowThreshold = lowWaterMarkBytes;
    _subscription = _channel.messageStream.listen((
      RTCDataChannelMessage message,
    ) {
      if (message.isBinary && !_messagesController.isClosed) {
        _messagesController.add(message.binary);
      }
    });
  }

  final RTCDataChannel _channel;
  final int highWaterMarkBytes;
  final int lowWaterMarkBytes;
  final Duration backpressureTimeout;

  final StreamController<Uint8List> _messagesController =
      StreamController<Uint8List>.broadcast();
  StreamSubscription<RTCDataChannelMessage>? _subscription;

  @override
  Stream<Uint8List> get messages => _messagesController.stream;

  @override
  Future<void> send(Uint8List bytes) async {
    await _waitUntilOpen();

    final DateTime deadline = DateTime.now().add(backpressureTimeout);
    while (await _channel.getBufferedAmount() > highWaterMarkBytes) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'Encoded video DataChannel remained backpressured.',
          backpressureTimeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    await _channel.send(RTCDataChannelMessage.fromBinary(bytes));
  }

  Future<void> _waitUntilOpen() async {
    if (_channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      return;
    }

    if (_channel.state == RTCDataChannelState.RTCDataChannelClosed ||
        _channel.state == RTCDataChannelState.RTCDataChannelClosing) {
      throw StateError('Encoded video DataChannel is closed.');
    }

    final RTCDataChannelState state = await _channel.stateChangeStream
        .firstWhere(
          (RTCDataChannelState value) =>
              value == RTCDataChannelState.RTCDataChannelOpen ||
              value == RTCDataChannelState.RTCDataChannelClosed ||
              value == RTCDataChannelState.RTCDataChannelClosing,
        )
        .timeout(backpressureTimeout);

    if (state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('Encoded video DataChannel closed before opening.');
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel.close();
    await _messagesController.close();
  }
}
