# Applying ABR to outbound WebRTC video

CastFlow now applies adaptive bitrate decisions to the active WebRTC video sender instead of keeping ABR as a policy-only calculation.

## Sender parameters

For every active video encoding, CastFlow updates:

- maximum bitrate
- maximum frame rate
- active state

The values come directly from the selected `StreamingProfile`.

`RTCRtpSender.setParameters()` is checked for success. A rejected update is treated as an explicit error rather than silently ignored.

## Separation of concerns

`AbrSenderController` knows only the domain-level `VideoSenderTuningPort`.

`WebRtcVideoSenderAdapter` is the boundary that translates a CastFlow streaming profile into `flutter_webrtc` RTP parameters.

This keeps ABR policy tests independent from native WebRTC initialization.

## Resolution

This increment intentionally does not pretend that sender bitrate changes also change capture resolution. Resolution changes remain a capture-layer responsibility. The next increment will synchronize the selected ABR profile with active screen-capture constraints.
