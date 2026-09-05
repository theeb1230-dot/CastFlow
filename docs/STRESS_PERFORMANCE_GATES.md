# Stress and performance gates

CastFlow includes deterministic CI stress gates for bounded resource behavior and recovery stability.

## Covered gates

- encoded H.264 chunk reassembly remains bounded under 10,000 incomplete-frame inserts
- concurrent transport-loss storms coalesce to one in-flight recovery attempt
- ABR remains in valid profiles through 10,000 alternating healthy/degraded samples
- 5,000 encode/decode/reassembly cycles must complete within a generous CI budget

These checks are intended to catch unbounded queues, reconnect stampedes, invalid ABR state, and large performance regressions.

## What this does not prove

CI stress tests are not a substitute for physical-device soak testing. Golden qualification still requires long-running Android Mobile, Android TV, and iOS device tests with real capture/rendering, memory observation, thermal behavior, reconnect/interruption scenarios, and latency/jitter/packet-loss measurements.
