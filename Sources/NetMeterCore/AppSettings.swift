public enum InterfaceSelection: String, Codable, CaseIterable, Sendable {
    case automatic
    case manual
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var startMonitoringAutomatically: Bool
    public var updateInterval: Double
    public var trackDailyUsage: Bool
    public var keepHistory: Bool
    public var historyRetentionDays: Int?
    public var interfaceSelection: InterfaceSelection
    public var selectedInterfaces: Set<String>

    public static let allowedIntervals: [Double] = [0.5, 1, 2, 5]
    public static let allowedRetentionDays: [Int] = [30, 90, 180, 365]

    public static let `default` = AppSettings(
        startMonitoringAutomatically: true,
        updateInterval: 1,
        trackDailyUsage: true,
        keepHistory: true,
        historyRetentionDays: 90,
        interfaceSelection: .automatic,
        selectedInterfaces: []
    )

    public var normalized: Self {
        var result = self
        if !Self.allowedIntervals.contains(updateInterval) { result.updateInterval = 1 }
        if let days = historyRetentionDays, !Self.allowedRetentionDays.contains(days) {
            result.historyRetentionDays = 90
        }
        return result
    }
}
