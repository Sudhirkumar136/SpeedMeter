import Foundation
import NetMeterCore

struct NetworkReading: Sendable {
    let sample: TrafficSample
    let interfaces: [InterfaceCounter]
}

actor NetworkMonitor {
    private var rateCalculator = TrafficRateCalculator()

    func read(settings: AppSettings) throws -> NetworkReading {
        let interfaces = try InterfaceCounterReader.read()
        let monitored = settings.interfaceSelection == .automatic
            ? interfaces
            : interfaces.filter { settings.selectedInterfaces.contains($0.name) }
        let sample = rateCalculator.consume(
            monitored,
            at: ProcessInfo.processInfo.systemUptime,
            expectedInterval: settings.updateInterval,
            mode: settings.interfaceSelection
        )
        return NetworkReading(sample: sample, interfaces: interfaces)
    }

    func reset() {
        rateCalculator.reset()
    }
}
