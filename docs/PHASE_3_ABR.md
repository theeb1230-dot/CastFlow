# Phase 3: Adaptive bitrate foundation

CastFlow now has a domain-level adaptive bitrate policy that converts measured WebRTC connection health into a streaming profile.

## Profiles

- 720p30 at 2.5 Mbps
- 720p60 at 4.5 Mbps
- 1080p30 at 6 Mbps
- 1080p60 at 9 Mbps

## Inputs

The policy consumes:

- RTT
- jitter
- packet loss
- available outgoing bitrate

## Hysteresis

A downgrade is allowed after two consecutive degraded samples.

An upgrade requires three consecutive stable samples.

This asymmetry is deliberate. Quality should drop quickly enough to protect latency and recover more cautiously to avoid oscillating between profiles.

## Next integration

The next Phase 3 increment will apply these profiles to actual WebRTC video sender parameters and the native capture pipeline.
