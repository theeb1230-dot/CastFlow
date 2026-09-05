import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../session/data/webrtc/webrtc_orchestrator.dart';
import '../../domain/entities/encoded_video_packet.dart';
import '../encoder/android_hardware_encoder.dart';
import '../transport/encoded_video_publisher.dart';
import '../transport/encoded_video_subscriber.dart';
import 'webrtc_datachannel_video_transport.dart';

class EncodedVideoWebRtcSession {
  EncodedVideoWebRtcSession({
    required WebRtcOrchestrator orchestrator,
    required AndroidHardwareEncoder encoder,
  }) : _orchestrator = orchestrator,
       _encoder = encoder;

  static const String channelLabel = 'castflow-h264';
  static const String channelProtocol = 'castflow-h264-v1';

  final WebRtcOrchestrator _orchestrator;
  final AndroidHardwareEncoder _encoder;

  final StreamController<EncodedVideoPacket> _remotePacketsController =
      StreamController<EncodedVideoPacket>.broadcast();

  StreamSubscription<RTCDataChannel>? _remoteChannelSubscription;
  StreamSubscription<EncodedVideoPacket>? _remotePacketSubscription;
  EncodedVideoPublisher? _publisher;
  EncodedVideoSubscriber? _subscriber;

  Stream<EncodedVideoPacket> get remotePackets =>
      _remotePacketsController.stream;

  Future<void> startSender() async {
    if (_publisher != null) {
      return;
    }

    final RTCDataChannel channel = await _orchestrator.createDataChannel(
      label: channelLabel,
      ordered: false,
      maxRetransmits: 0,
      protocol: channelProtocol,
    );

    final WebRtcDataChannelVideoTransport transport =
        WebRtcDataChannelVideoTransport(channel);
    final EncodedVideoPublisher publisher = EncodedVideoPublisher(
      transport: transport,
    );
    publisher.bind(_encoder.packets);
    _publisher = publisher;
  }

  void startReceiver() {
    _remoteChannelSubscription ??= _orchestrator.dataChannels
        .where(
          (RTCDataChannel channel) =>
              channel.label == channelLabel &&
              channel.protocol == channelProtocol,
        )
        .listen(_attachRemoteChannel);
  }

  Future<void> dispose() async {
    await _remoteChannelSubscription?.cancel();
    _remoteChannelSubscription = null;

    await _remotePacketSubscription?.cancel();
    _remotePacketSubscription = null;

    await _publisher?.dispose();
    _publisher = null;

    await _subscriber?.dispose();
    _subscriber = null;

    await _remotePacketsController.close();
  }

  void _attachRemoteChannel(RTCDataChannel channel) {
    if (_subscriber != null) {
      return;
    }

    final EncodedVideoSubscriber subscriber = EncodedVideoSubscriber(
      transport: WebRtcDataChannelVideoTransport(channel),
    );
    subscriber.start();

    _remotePacketSubscription = subscriber.packets.listen(
      _remotePacketsController.add,
      onError: _remotePacketsController.addError,
    );
    _subscriber = subscriber;
  }
}
