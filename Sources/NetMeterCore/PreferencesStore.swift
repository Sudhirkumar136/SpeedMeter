import Foundation

public struct TrafficTotals: Codable, Equatable, Sendable {
    public var downloaded: UInt64
    public var uploaded: UInt64

    public init(downloaded: UInt64, uploaded: UInt64) {
        self.downloaded = downloaded
        self.uploaded = uploaded
    }

    public static let zero = TrafficTotals(downloaded: 0, uploaded: 0)

    public var total: UInt64 {
        let sum = downloaded.addingReportingOverflow(uploaded)
        return sum.overflow ? UInt64.max : sum.partialValue
    }

    public mutating func add(_ delta: TrafficDelta) {
        downloaded = downloaded.addingReportingOverflow(delta.received).overflow
            ? UInt64.max : downloaded + delta.received
        uploaded = uploaded.addingReportingOverflow(delta.sent).overflow
            ? UInt64.max : uploaded + delta.sent
    }
}

public final class PreferencesStore {
    private let defaults: UserDefaults
    private let configurationKey = "displayConfiguration"
    private let totalsKey = "trafficTotals"
    private let settingsKey = "appSettings"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadConfiguration() -> DisplayConfiguration {
        guard let data = defaults.data(forKey: configurationKey),
              let configuration = try? JSONDecoder().decode(DisplayConfiguration.self, from: data)
        else { return .default }
        return configuration.normalized
    }

    public func save(configuration: DisplayConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration.normalized) else { return }
        defaults.set(data, forKey: configurationKey)
    }

    public func loadTotals() -> TrafficTotals {
        guard let data = defaults.data(forKey: totalsKey),
              let totals = try? JSONDecoder().decode(TrafficTotals.self, from: data)
        else { return .zero }
        return totals
    }

    public func save(totals: TrafficTotals) {
        guard let data = try? JSONEncoder().encode(totals) else { return }
        defaults.set(data, forKey: totalsKey)
    }

    public func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .default }
        return settings.normalized
    }

    public func save(settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings.normalized) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
