import ReplayKit

final class SampleHandler: RPBroadcastSampleHandler {
    private let appGroup = "group.com.castflow.shared"
    private let heartbeatKey = "replaykit.lastHeartbeat"
    private let stateKey = "replaykit.state"
    private var processedVideoSamples = 0
    private var encoder: VideoToolboxH264Encoder?
    private var spool: ReplayKitEncodedFrameSpool?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        processedVideoSamples = 0
        spool = try? ReplayKitEncodedFrameSpool(appGroup: appGroup)
        spool?.reset()
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
        encoder?.finish()
        encoder = nil
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
            do {
                try ensureEncoder(for: sampleBuffer)
                encoder?.encode(sampleBuffer)
                processedVideoSamples += 1
                if processedVideoSamples % 30 == 0 {
                    writeHeartbeat()
                }
            } catch {
                updateSharedState("encoder-error")
                finishBroadcastWithError(error)
            }
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }

    private func ensureEncoder(for sampleBuffer: CMSampleBuffer) throws {
        guard encoder == nil else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw NSError(domain: "CastFlow.ReplayKit", code: 2)
        }

        let width = Int32(CVPixelBufferGetWidth(imageBuffer))
        let height = Int32(CVPixelBufferGetHeight(imageBuffer))
        let frameSpool = spool
        encoder = try VideoToolboxH264Encoder(width: width, height: height) { frame in
            frameSpool?.append(frame)
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
