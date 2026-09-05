import 'package:castflow/features/session/data/webrtc/webrtc_stats_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  const WebRtcStatsParser parser = WebRtcStatsParser();

  test('extracts RTT, jitter, loss and bitrate metrics', () {
    final List<StatsReport> reports = <StatsReport>[
      StatsReport(
        'candidate-1',
        'candidate-pair',
        1,
        <String, Object?>{
          'state': 'succeeded',
          'currentRoundTripTime': 0.042,
          'availableOutgoingBitrate': 8500000,
        },
      ),
      StatsReport(
        'inbound-1',
        'inbound-rtp',
        1,
        <String, Object?>{
          'jitter': 0.007,
          'packetsLost': 5,
          'packetsReceived': 995,
          'bytesReceived': 4000000,
        },
      ),
      StatsReport(
        'outbound-1',
        'outbound-rtp',
        1,
        <String, Object?>{'bytesSent': 5000000},
      ),
    ];

    final metrics = parser.parse(reports);

    expect(metrics.roundTripTimeMs, 42);
    expect(metrics.jitterMs, 7);
    expect(metrics.packetLossRate, closeTo(0.005, 0.00001));
    expect(metrics.availableOutgoingBitrateBps, 8500000);
    expect(metrics.bytesSent, 5000000);
    expect(metrics.bytesReceived, 4000000);
    expect(metrics.isDegraded, isFalse);
  });

  test('marks materially degraded connections', () {
    final List<StatsReport> reports = <StatsReport>[
      StatsReport(
        'candidate-1',
        'candidate-pair',
        1,
        <String, Object?>{
          'selected': true,
          'currentRoundTripTime': 0.15,
        },
      ),
      StatsReport(
        'inbound-1',
        'inbound-rtp',
        1,
        <String, Object?>{
          'jitter': 0.04,
          'packetsLost': 60,
          'packetsReceived': 940,
        },
      ),
    ];

    final metrics = parser.parse(reports);

    expect(metrics.packetLossRate, closeTo(0.06, 0.00001));
    expect(metrics.isDegraded, isTrue);
  });

  test('returns safe zero-loss defaults for empty stats', () {
    final metrics = parser.parse(const <StatsReport>[]);

    expect(metrics.roundTripTimeMs, isNull);
    expect(metrics.jitterMs, isNull);
    expect(metrics.packetLossRate, 0);
    expect(metrics.bytesSent, 0);
    expect(metrics.bytesReceived, 0);
    expect(metrics.isDegraded, isFalse);
  });
}
