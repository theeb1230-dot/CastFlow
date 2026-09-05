import Flutter
import Foundation

final class ReplayKitSpoolBridge: NSObject, FlutterStreamHandler {
    private static var retainedBridge: ReplayKitSpoolBridge?

    static func register(with registry: FlutterPluginRegistry) {
        guard let registrar = registry.registrar(forPlugin: "ReplayKitSpoolBridge") else {
            return
        }
        let bridge = ReplayKitSpoolBridge()
        let channel = FlutterEventChannel(
            name: "castflow/replaykit_encoded/events",
            binaryMessenger: registrar.messenger()
        )
        channel.setStreamHandler(bridge)
        retainedBridge = bridge
    }

    private let appGroup = "group.com.castflow.shared"
    private let queue = DispatchQueue(label: "com.castflow.replaykit.reader")
    private var timer: DispatchSourceTimer?
    private var eventSink: FlutterEventSink?
    private var offset: UInt64 = 0
    private var pending = Data()

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        stopReading()
        eventSink = events
        offset = 0
        pending.removeAll(keepingCapacity: true)

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(8),
            leeway: .milliseconds(2)
        )
        timer.setEventHandler { [weak self] in
            self?.drain()
        }
        self.timer = timer
        timer.resume()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopReading()
        eventSink = nil
        return nil
    }

    private func stopReading() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
        pending.removeAll(keepingCapacity: false)
    }

    private func drain() {
        guard
            let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroup
            )
        else {
            return
        }

        let url = container.appendingPathComponent("encoded-video.bin")
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let fileSizeNumber = attributes[.size] as? NSNumber
        else {
            return
        }

        let fileSize = fileSizeNumber.uint64Value
        if fileSize < offset {
            offset = 0
            pending.removeAll(keepingCapacity: true)
        }
        guard fileSize > offset else {
            return
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return
        }
        defer { try? handle.close() }

        do {
            try handle.seek(toOffset: offset)
            let available = Int(min(fileSize - offset, 1024 * 1024))
            guard
                available > 0,
                let data = try handle.read(upToCount: available),
                !data.isEmpty
            else {
                return
            }
            offset += UInt64(data.count)
            pending.append(data)
            parsePending()
        } catch {
            return
        }
    }

    private func parsePending() {
        let headerSize = 16
        let maximumPayloadSize = 4 * 1024 * 1024

        while pending.count >= headerSize {
            let presentationTimeUs = readInt64BigEndian(from: pending, at: 0)
            let flags = readUInt32BigEndian(from: pending, at: 8)
            let payloadLength = Int(readUInt32BigEndian(from: pending, at: 12))

            guard payloadLength >= 0, payloadLength <= maximumPayloadSize else {
                pending.removeAll(keepingCapacity: true)
                return
            }

            let recordLength = headerSize + payloadLength
            guard pending.count >= recordLength else {
                return
            }

            let payload = pending.subdata(in: headerSize..<recordLength)
            pending.removeSubrange(0..<recordLength)

            let message: [String: Any] = [
                "data": FlutterStandardTypedData(bytes: payload),
                "presentationTimeUs": presentationTimeUs,
                "flags": Int64(flags),
            ]
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?(message)
            }
        }
    }

    private func readUInt32BigEndian(from data: Data, at offset: Int) -> UInt32 {
        var value: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &value) { buffer in
            data.copyBytes(
                to: buffer.bindMemory(to: UInt8.self),
                from: offset..<(offset + MemoryLayout<UInt32>.size)
            )
        }
        return UInt32(bigEndian: value)
    }

    private func readInt64BigEndian(from data: Data, at offset: Int) -> Int64 {
        var value: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &value) { buffer in
            data.copyBytes(
                to: buffer.bindMemory(to: UInt8.self),
                from: offset..<(offset + MemoryLayout<UInt64>.size)
            )
        }
        return Int64(bitPattern: UInt64(bigEndian: value))
    }
}
