import Flutter
import Foundation

final class ReplayKitLifecycleBridge: NSObject, FlutterStreamHandler {
    private static var retainedBridge: ReplayKitLifecycleBridge?

    static func register(with registry: FlutterPluginRegistry) {
        guard let registrar = registry.registrar(forPlugin: "ReplayKitLifecycleBridge") else {
            return
        }
        let bridge = ReplayKitLifecycleBridge()
        let channel = FlutterEventChannel(
            name: "castflow/replaykit_lifecycle/events",
            binaryMessenger: registrar.messenger()
        )
        channel.setStreamHandler(bridge)
        retainedBridge = bridge
    }

    private let appGroup = "group.com.castflow.shared"
    private let queue = DispatchQueue(label: "com.castflow.replaykit.lifecycle")
    private var timer: DispatchSourceTimer?
    private var eventSink: FlutterEventSink?
    private var lastSignature: String?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        stopPolling()
        eventSink = events
        lastSignature = nil

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(250),
            leeway: .milliseconds(50)
        )
        timer.setEventHandler { [weak self] in
            self?.poll()
        }
        self.timer = timer
        timer.resume()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopPolling()
        eventSink = nil
        return nil
    }

    private func stopPolling() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func poll() {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return
        }

        let state = defaults.string(forKey: "replaykit.state") ?? "idle"
        let heartbeat = defaults.double(forKey: "replaykit.lastHeartbeat")
        let videoSamples = defaults.integer(forKey: "replaykit.videoSamples")
        let signature = "\(state)|\(heartbeat)|\(videoSamples)"

        guard signature != lastSignature else {
            return
        }
        lastSignature = signature

        let message: [String: Any] = [
            "state": state,
            "lastHeartbeat": heartbeat,
            "videoSamples": videoSamples,
        ]

        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(message)
        }
    }
}
