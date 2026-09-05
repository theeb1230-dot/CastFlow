# Phase 3: Adaptive bitrate control

CastFlow's ABR controller consumes the measured WebRTC connection metrics introduced in Phase 2.

## Profiles

- Low: 1280x720 @ 30 fps, 2.5 Mbps target
- Balanced: 1920x1080 @ 30 fps, 5 Mbps target
- High: 1920x1080 @ 60 fps, 8 Mbps target

## Hysteresis

A profile downgrade requires two consecutive degraded samples.

A profile upgrade requires five consecutive healthy samples with enough measured outgoing bitrate headroom for the next profile.

This asymmetry makes degradation responsive while preventing rapid quality oscillation during short-lived network spikes.

## Current control signals

A sample is degraded when the measured connection crosses the Phase 2 thresholds or available outgoing bitrate falls below 90% of the active profile target.

An upgrade additionally requires:

- packet loss below 2%
- RTT below 80 ms when available
- jitter below 20 ms when available
- at least 1.35x bitrate headroom over the next profile target

## Next integration

The next Phase 3 increment will apply the selected profile to the active WebRTC sender/capture pipeline rather than only selecting the target profile.
