# WebRTC connection metrics

CastFlow treats ultra-low latency as a measurable engineering target rather than a literal zero-latency guarantee.

The metrics layer reads WebRTC `getStats()` reports and derives:

- current round-trip time (RTT)
- RTP jitter
- packet loss rate
- available outgoing bitrate
- bytes sent and received
- packets lost and received

These values are intentionally represented in the domain layer without exposing `flutter_webrtc` types.

## Units

- RTT: milliseconds
- jitter: milliseconds
- packet loss: 0.0 to 1.0
- available outgoing bitrate: bits per second
- bytes/packets: cumulative counters from WebRTC

## Initial degradation threshold

A connection is considered degraded when any of the following is true:

- packet loss >= 5%
- RTT >= 120 ms
- jitter >= 30 ms

These are initial control thresholds, not permanent product guarantees. Phase 3 ABR will use measured trends rather than a single sample to select resolution, frame rate and encoder bitrate.
