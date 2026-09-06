# Stress, resource-bound, and performance gates

CastFlow treats CI stress tests as regression gates, not as proof of physical-device soak stability.

## Deterministic resource gates

The stress suite verifies:

- encoded H.264 reassembly never retains more than the configured pending-frame bound under thousands of incomplete frames
- recovery attempts reset across repeated successful reconnect cycles instead of accumulating stale state
- authenticated local signaling sockets are released after repeated connect/disconnect cycles
- the local signaling server enforces a hard concurrent-client bound to reduce accidental or malicious resource exhaustion

These checks are deterministic and fail closed in pull-request CI.

## Performance smoke gate

The encoded-video framing path processes 1,000 32 KiB access units through split, encode, decode, and reassembly. CI allows a deliberately broad 15-second ceiling. The threshold is intended to catch major algorithmic regressions, not to claim device latency.

## What this does not prove

Golden and Complete qualification still require physical-device evidence:

- sustained Android Mobile sender capture
- Android TV receiver rendering and D-Pad operation
- iOS ReplayKit + VideoToolbox on a provisioned device
- long-duration soak tests
- process memory and native heap observation
- reconnect/interruption loops on real radios
- RTT, jitter, packet-loss, and ABR measurements under controlled network impairment

Simulator and hosted-runner success cannot substitute for those device gates.
