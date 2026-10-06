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

public enum MenuBarFontWeight: String, CaseIterable, Codable, Sendable {
    case regular
    case medium
    case semibold
    case bold

    public var title: String {
        switch self {
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "Semibold"
        case .bold: "Bold"
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
    public var menuBarFontSize: Int
    public var downloadFontWeight: MenuBarFontWeight
    public var uploadFontWeight: MenuBarFontWeight

    public init(
        order: [Metric],
        enabled: Set<Metric>,
        speedUnit: SpeedUnit,
        decimalPrecision: Int,
        symbolStyle: SymbolStyle,
        showUnits: Bool,
        menuBarFontSize: Int = 12,
        downloadFontWeight: MenuBarFontWeight = .regular,
        uploadFontWeight: MenuBarFontWeight = .regular
    ) {
        self.order = order
        self.enabled = enabled
        self.speedUnit = speedUnit
        self.decimalPrecision = decimalPrecision
        self.symbolStyle = symbolStyle
        self.showUnits = showUnits
        self.menuBarFontSize = menuBarFontSize
        self.downloadFontWeight = downloadFontWeight
        self.uploadFontWeight = uploadFontWeight
    }

    public static let `default` = DisplayConfiguration(
        order: Metric.allCases,
        enabled: [.downloadSpeed, .uploadSpeed],
        speedUnit: .auto,
        decimalPrecision: 1,
        symbolStyle: .arrows,
        showUnits: true,
        menuBarFontSize: 12,
        downloadFontWeight: .regular,
        uploadFontWeight: .regular
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
            showUnits: showUnits,
            menuBarFontSize: min(14, max(10, menuBarFontSize)),
            downloadFontWeight: downloadFontWeight,
            uploadFontWeight: uploadFontWeight
        )
    }

    private enum CodingKeys: String, CodingKey {
        case order, enabled, speedUnit, decimalPrecision, symbolStyle, showUnits
        case menuBarFontSize, downloadFontWeight, uploadFontWeight
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            order: try values.decode([Metric].self, forKey: .order),
            enabled: try values.decode(Set<Metric>.self, forKey: .enabled),
            speedUnit: try values.decode(SpeedUnit.self, forKey: .speedUnit),
            decimalPrecision: try values.decode(Int.self, forKey: .decimalPrecision),
            symbolStyle: try values.decode(SymbolStyle.self, forKey: .symbolStyle),
            showUnits: try values.decode(Bool.self, forKey: .showUnits),
            menuBarFontSize: try values.decodeIfPresent(Int.self, forKey: .menuBarFontSize) ?? 12,
            downloadFontWeight: try values.decodeIfPresent(MenuBarFontWeight.self, forKey: .downloadFontWeight) ?? .regular,
            uploadFontWeight: try values.decodeIfPresent(MenuBarFontWeight.self, forKey: .uploadFontWeight) ?? .regular
        )
    }
}
