public struct InterfaceCounter: Equatable, Sendable {
    public let name: String
    public let received: UInt64
    public let sent: UInt64
    public let isUp: Bool
    public let isRunning: Bool

    public init(name: String, received: UInt64, sent: UInt64, isUp: Bool, isRunning: Bool) {
        self.name = name
        self.received = received
        self.sent = sent
        self.isUp = isUp
        self.isRunning = isRunning
    }
}

public struct TrafficDelta: Equatable, Sendable {
    public let received: UInt64
    public let sent: UInt64

    public init(received: UInt64, sent: UInt64) {
        self.received = received
        self.sent = sent
    }
}

public struct TrafficDeltaCalculator: Sendable {
    private var previous: [String: InterfaceCounter] = [:]

    public init() {}

    public mutating func consume(
        _ counters: [InterfaceCounter],
        mode: InterfaceSelection = .automatic
    ) -> TrafficDelta {
        let current = Dictionary(counters.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })

        let active = current.values.filter { counter in
            counter.isUp && counter.isRunning && (mode == .manual || !Self.isExcluded(counter.name))
        }
        let physical = active.filter { !$0.name.hasPrefix("utun") && !$0.name.hasPrefix("tun") }
        let selected = mode == .manual ? active : (physical.isEmpty ? active : physical)
        defer { previous = Dictionary(selected.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last }) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        for counter in selected {
            guard let prior = previous[counter.name] else { continue }
            if counter.received >= prior.received {
                let sum = received.addingReportingOverflow(counter.received - prior.received)
                received = sum.overflow ? UInt64.max : sum.partialValue
            }
            if counter.sent >= prior.sent {
                let sum = sent.addingReportingOverflow(counter.sent - prior.sent)
                sent = sum.overflow ? UInt64.max : sum.partialValue
            }
        }
        return TrafficDelta(received: received, sent: sent)
    }

    private static func isExcluded(_ name: String) -> Bool {
        ["lo", "awdl", "llw", "anpi", "ap", "p2p", "gif", "stf", "vmnet", "vboxnet"].contains {
            name.hasPrefix($0)
        }
    }
}
