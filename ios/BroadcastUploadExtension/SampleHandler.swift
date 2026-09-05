import ReplayKit

final class SampleHandler: RPBroadcastSampleHandler {
    private let appGroup = "group.com.castflow.shared"
    private let heartbeatKey = "replaykit.lastHeartbeat"
    private let stateKey = "replaykit.state"
    private var processedVideoSamples = 0

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        processedVideoSamples = 0
        updateSharedState("started")
        writeHeartbeat()
    }

    override func broadcastPaused() {
        updateSharedState("paused")
        writeHeartbeat()
    }

    override func broadcastResumed() {
        updateSharedState("resumed")
        writeHeartbeat()
    }

    override func broadcastFinished() {
        updateSharedState("finished")
        writeHeartbeat()
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            return
        }

        switch sampleBufferType {
        case .video:
            processedVideoSamples += 1
            if processedVideoSamples % 30 == 0 {
                writeHeartbeat()
            }
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }

    private func updateSharedState(_ state: String) {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return
        }
        defaults.set(state, forKey: stateKey)
        defaults.set(processedVideoSamples, forKey: "replaykit.videoSamples")
    }

    private func writeHeartbeat() {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return
        }
        defaults.set(Date().timeIntervalSince1970, forKey: heartbeatKey)
        defaults.set(processedVideoSamples, forKey: "replaykit.videoSamples")
    }
}
