import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/entities/streaming_profile.dart';
import '../../domain/repositories/video_sender_tuning_port.dart';

class WebRtcVideoSenderAdapter implements VideoSenderTuningPort {
  WebRtcVideoSenderAdapter(this._sender);

  final RTCRtpSender _sender;

  @override
  Future<void> applyProfile(StreamingProfile profile) async {
    final MediaStreamTrack? track = _sender.track;
    if (track == null || track.kind != 'video') {
      throw StateError('ABR can only be applied to an active video sender.');
    }

    final RTCRtpParameters parameters = _sender.parameters;
    final List<RTCRtpEncoding> encodings =
        parameters.encodings ?? <RTCRtpEncoding>[RTCRtpEncoding()];

    for (final RTCRtpEncoding encoding in encodings) {
      encoding.active = true;
      encoding.maxBitrate = profile.targetBitrateBps;
      encoding.maxFramerate = profile.framesPerSecond;
    }

    parameters.encodings = encodings;

    final bool applied = await _sender.setParameters(parameters);
    if (!applied) {
      throw StateError('WebRTC rejected the requested sender parameters.');
    }
  }
}
