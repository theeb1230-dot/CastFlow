import Foundation
import VideoToolbox
import CoreMedia

final class VideoToolboxH264Encoder {
    struct EncodedFrame {
        let bytes: Data
        let presentationTimeUs: Int64
        let isKeyFrame: Bool
    }

    private var session: VTCompressionSession?
    private let output: (EncodedFrame) -> Void

    init(width: Int32, height: Int32, framesPerSecond: Int32 = 30, bitrate: Int32 = 6_000_000, output: @escaping (EncodedFrame) -> Void) throws {
        self.output = output

        var created: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: { refCon, _, status, _, sampleBuffer in
                guard status == noErr,
                      let refCon,
                      let sampleBuffer,
                      CMSampleBufferDataIsReady(sampleBuffer) else { return }
                let encoder = Unmanaged<VideoToolboxH264Encoder>.fromOpaque(refCon).takeUnretainedValue()
                encoder.handle(sampleBuffer)
            },
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &created
        )
        guard status == noErr, let created else {
            throw NSError(domain: "CastFlow.VideoToolbox", code: Int(status))
        }

        session = created
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_High_AutoLevel)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: framesPerSecond as CFTypeRef)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFTypeRef)
        let dataRateLimit: [Int] = [Int(bitrate / 8), 1]
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_DataRateLimits, value: dataRateLimit as CFArray)
        VTCompressionSessionPrepareToEncodeFrames(created)
    }

    func encode(_ sampleBuffer: CMSampleBuffer) {
        guard let session, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: pts,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }

    func finish() {
        guard let session else { return }
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(session)
        self.session = nil
    }

    deinit {
        finish()
    }

    private func handle(_ sampleBuffer: CMSampleBuffer) {
        let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]]
        let isKeyFrame = !(attachments?.first?[kCMSampleAttachmentKey_NotSync] as? Bool ?? false)

        var annexB = Data()
        if isKeyFrame, let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
            appendParameterSets(from: format, to: &annexB)
        }

        guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
        guard status == kCMBlockBufferNoErr, let dataPointer else { return }

        var offset = 0
        while offset + 4 <= totalLength {
            var nalLengthBE: UInt32 = 0
            memcpy(&nalLengthBE, dataPointer.advanced(by: offset), 4)
            let nalLength = Int(UInt32(bigEndian: nalLengthBE))
            offset += 4
            guard nalLength > 0, offset + nalLength <= totalLength else { return }
            annexB.append(contentsOf: [0, 0, 0, 1])
            annexB.append(Data(bytes: dataPointer.advanced(by: offset), count: nalLength))
            offset += nalLength
        }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let us = pts.isNumeric ? Int64((CMTimeGetSeconds(pts) * 1_000_000.0).rounded()) : 0
        output(EncodedFrame(bytes: annexB, presentationTimeUs: us, isKeyFrame: isKeyFrame))
    }

    private func appendParameterSets(from format: CMFormatDescription, to data: inout Data) {
        var parameterSetCount = 0
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            format,
            parameterSetIndex: 0,
            parameterSetPointerOut: nil,
            parameterSetSizeOut: nil,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: nil
        )

        for index in 0..<parameterSetCount {
            var pointer: UnsafePointer<UInt8>?
            var size = 0
            let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                format,
                parameterSetIndex: index,
                parameterSetPointerOut: &pointer,
                parameterSetSizeOut: &size,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            guard status == noErr, let pointer, size > 0 else { continue }
            data.append(contentsOf: [0, 0, 0, 1])
            data.append(Data(bytes: pointer, count: size))
        }
    }
}

final class ReplayKitEncodedFrameSpool {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.castflow.replaykit.spool")
    private let maxBytes: UInt64 = 8 * 1024 * 1024

    init(appGroup: String) throws {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw NSError(domain: "CastFlow.ReplayKit", code: 1)
        }
        fileURL = container.appendingPathComponent("encoded-video.bin")
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
    }

    func reset() {
        queue.sync {
            try? Data().write(to: fileURL, options: .atomic)
        }
    }

    func append(_ frame: VideoToolboxH264Encoder.EncodedFrame) {
        queue.async {
            guard frame.bytes.count <= Int(UInt32.max) else { return }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: self.fileURL.path),
               let size = attrs[.size] as? NSNumber,
               size.uint64Value > self.maxBytes {
                try? Data().write(to: self.fileURL, options: .atomic)
            }

            var record = Data()
            var pts = frame.presentationTimeUs.bigEndian
            var flags: UInt32 = frame.isKeyFrame ? 1 : 0
            flags = flags.bigEndian
            var length = UInt32(frame.bytes.count).bigEndian
            withUnsafeBytes(of: &pts) { record.append(contentsOf: $0) }
            withUnsafeBytes(of: &flags) { record.append(contentsOf: $0) }
            withUnsafeBytes(of: &length) { record.append(contentsOf: $0) }
            record.append(frame.bytes)

            guard let handle = try? FileHandle(forWritingTo: self.fileURL) else { return }
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: record)
            } catch {
                return
            }
        }
    }
}
