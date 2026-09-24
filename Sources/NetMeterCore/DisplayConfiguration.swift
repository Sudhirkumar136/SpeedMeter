public enum Metric: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case downloadSpeed
    case uploadSpeed
    case totalDownloaded
    case totalUploaded
    case totalUsed

    public var id: Self { self }

    public var title: String {
        switch self {
        case .downloadSpeed: "Download Speed"
        case .uploadSpeed: "Upload Speed"
        case .totalDownloaded: "Total Downloaded"
        case .totalUploaded: "Total Uploaded"
        case .totalUsed: "Total Data Used"
        }
    }
}

public enum SpeedUnit: String, CaseIterable, Codable, Sendable {
    case auto
    case kilobytes
    case megabytes
    case megabits
    case gigabits

    public var title: String {
        switch self {
        case .auto: "Auto"
        case .kilobytes: "KB/s"
        case .megabytes: "MB/s"
        case .megabits: "Mbps"
        case .gigabits: "Gbps"
        }
    }
}

public enum SymbolStyle: String, CaseIterable, Codable, Sendable {
    case arrows
    case thinArrows
    case shortLabels
    case longLabels

    public var title: String {
        switch self {
        case .arrows: "↓ ↑"
        case .thinArrows: "⇣ ⇡"
        case .shortLabels: "D: U:"
        case .longLabels: "DL: UL:"
        }
    }

    public var download: String {
        switch self {
        case .arrows: "↓"
        case .thinArrows: "⇣"
        case .shortLabels: "D:"
        case .longLabels: "DL:"
        }
    }

    public var upload: String {
        switch self {
        case .arrows: "↑"
        case .thinArrows: "⇡"
        case .shortLabels: "U:"
        case .longLabels: "UL:"
        }
    }
}

public struct DisplayConfiguration: Codable, Equatable, Sendable {
    public var order: [Metric]
    public var enabled: Set<Metric>
    public var speedUnit: SpeedUnit
    public var decimalPrecision: Int
    public var symbolStyle: SymbolStyle
    public var showUnits: Bool

    public init(
        order: [Metric],
        enabled: Set<Metric>,
        speedUnit: SpeedUnit,
        decimalPrecision: Int,
        symbolStyle: SymbolStyle,
        showUnits: Bool
    ) {
        self.order = order
        self.enabled = enabled
        self.speedUnit = speedUnit
        self.decimalPrecision = decimalPrecision
        self.symbolStyle = symbolStyle
        self.showUnits = showUnits
    }

    public static let `default` = DisplayConfiguration(
        order: Metric.allCases,
        enabled: [.downloadSpeed, .uploadSpeed],
        speedUnit: .auto,
        decimalPrecision: 1,
        symbolStyle: .arrows,
        showUnits: true
    )

    public var normalized: Self {
        var seen = Set<Metric>()
        let validOrder = (order + Metric.allCases).filter { seen.insert($0).inserted }
        return Self(
            order: validOrder,
            enabled: Set(validOrder.filter { enabled.contains($0) }.prefix(3)),
            speedUnit: speedUnit,
            decimalPrecision: min(2, max(0, decimalPrecision)),
            symbolStyle: symbolStyle,
            showUnits: showUnits
        )
    }
}
