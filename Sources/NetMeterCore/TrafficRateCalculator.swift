import Foundation

public struct TrafficSample: Equatable, Sendable {
    public let downloadBytesPerSecond: UInt64
    public let uploadBytesPerSecond: UInt64
    public let delta: TrafficDelta

    public init(downloadBytesPerSecond: UInt64, uploadBytesPerSecond: UInt64, delta: TrafficDelta) {
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.delta = delta
    }

    public static let zero = TrafficSample(
        downloadBytesPerSecond: 0,
        uploadBytesPerSecond: 0,
        delta: TrafficDelta(received: 0, sent: 0)
    )
}

public struct TrafficRateCalculator: Sendable {
    private var deltas = TrafficDeltaCalculator()
    private var previousTime: TimeInterval?

    public init() {}

    public mutating func reset() {
        deltas = TrafficDeltaCalculator()
        previousTime = nil
    }

    public mutating func consume(
        _ counters: [InterfaceCounter],
        at time: TimeInterval,
        expectedInterval: TimeInterval,
        mode: InterfaceSelection = .automatic
    ) -> TrafficSample {
        let delta = deltas.consume(counters, mode: mode)
        defer { previousTime = time }
        guard let previousTime else { return .zero }
        let elapsed = time - previousTime
        guard elapsed >= max(0.05, expectedInterval * 0.25),
              elapsed <= max(10, expectedInterval * 3)
        else { return .zero }
        func safeRate(_ bytes: UInt64) -> UInt64 {
            let value = Double(bytes) / elapsed
            return value >= Double(UInt64.max) ? UInt64.max : UInt64(value)
        }
        return TrafficSample(
            downloadBytesPerSecond: safeRate(delta.received),
            uploadBytesPerSecond: safeRate(delta.sent),
            delta: delta
        )
    }
}
