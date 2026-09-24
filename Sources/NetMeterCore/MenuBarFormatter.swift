import Foundation

public enum ByteUnitFormatter {
    public static func format(_ bytes: UInt64, decimals: Int = 1, fixedDecimals: Bool = false) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var index = 0
        while value >= 1_024 && index < units.count - 1 {
            value /= 1_024
            index += 1
        }
        let places = fixedDecimals || index > 0 ? decimals : 0
        return "\(formatNumber(value, decimals: places, fixedDecimals: fixedDecimals)) \(units[index])"
    }
}

public enum SpeedFormatter {
    public static func format(_ bytesPerSecond: UInt64, unit: SpeedUnit, decimals: Int, fixedDecimals: Bool = false) -> String {
        let value = Double(bytesPerSecond)
        let scaled: Double
        let suffix: String
        switch unit {
        case .auto:
            return "\(ByteUnitFormatter.format(bytesPerSecond, decimals: decimals, fixedDecimals: fixedDecimals))/s"
        case .kilobytes:
            scaled = value / 1_024
            suffix = "KB/s"
        case .megabytes:
            scaled = value / 1_048_576
            suffix = "MB/s"
        case .megabits:
            scaled = value * 8 / 1_000_000
            suffix = "Mbps"
        case .gigabits:
            scaled = value * 8 / 1_000_000_000
            suffix = "Gbps"
        }
        return "\(formatNumber(scaled, decimals: decimals, fixedDecimals: fixedDecimals)) \(suffix)"
    }
}

private func formatNumber(_ value: Double, decimals: Int, fixedDecimals: Bool) -> String {
    let precision = min(2, max(0, decimals))
    var formatted = String(format: "%.*f", locale: Locale(identifier: "en_US_POSIX"), precision, value)
    if fixedDecimals { return formatted }
    guard formatted.contains(".") else { return formatted }
    while formatted.last == "0" { formatted.removeLast() }
    if formatted.last == "." { formatted.removeLast() }
    return formatted
}

public struct MenuBarMetricText: Identifiable, Sendable {
    public let metric: Metric
    public let text: String

    public var id: Metric { metric }
}

public enum MenuBarFormatter {
    public static func render(
        downloadBytesPerSecond: UInt64,
        uploadBytesPerSecond: UInt64,
        totalDownloaded: UInt64,
        totalUploaded: UInt64,
        configuration: DisplayConfiguration
    ) -> String {
        let config = configuration.normalized
        let visible = config.order.filter { config.enabled.contains($0) }
        guard !visible.isEmpty else { return "NetMeter" }
        let total = totalDownloaded.addingReportingOverflow(totalUploaded)
        let totalUsed = total.overflow ? UInt64.max : total.partialValue
        return visible.map { metric in
            let prefix: String
            let value: String
            switch metric {
            case .downloadSpeed:
                prefix = config.symbolStyle.download
                value = compactSpeed(downloadBytesPerSecond, config)
            case .uploadSpeed:
                prefix = config.symbolStyle.upload
                value = compactSpeed(uploadBytesPerSecond, config)
            case .totalDownloaded:
                prefix = "\(config.symbolStyle.download)Σ"
                value = compactBytes(totalDownloaded, config)
            case .totalUploaded:
                prefix = "\(config.symbolStyle.upload)Σ"
                value = compactBytes(totalUploaded, config)
            case .totalUsed:
                prefix = "Σ"
                value = compactBytes(totalUsed, config)
            }
            let padding = max(0, columnWidth(for: metric, config) - prefix.count - value.count)
            return prefix + String(repeating: " ", count: padding) + value
        }.joined(separator: " ")
    }

    public static func reservedCharacterCount(configuration: DisplayConfiguration) -> Int {
        let config = configuration.normalized
        let visible = config.order.filter { config.enabled.contains($0) }
        guard !visible.isEmpty else { return "NetMeter".count }
        return visible.map { columnWidth(for: $0, config) }.reduce(0, +) + visible.count - 1
    }

    public static func items(
        downloadBytesPerSecond: UInt64,
        uploadBytesPerSecond: UInt64,
        totalDownloaded: UInt64,
        totalUploaded: UInt64,
        configuration: DisplayConfiguration
    ) -> [MenuBarMetricText] {
        let config = configuration.normalized
        let total = totalDownloaded.addingReportingOverflow(totalUploaded)
        let totalUsed = total.overflow ? UInt64.max : total.partialValue
        return config.order.filter { config.enabled.contains($0) }.map { metric in
            let text = switch metric {
            case .downloadSpeed:
                "\(config.symbolStyle.download) \(speed(downloadBytesPerSecond, config))"
            case .uploadSpeed:
                "\(config.symbolStyle.upload) \(speed(uploadBytesPerSecond, config))"
            case .totalDownloaded:
                "\(config.symbolStyle.download)Σ \(bytes(totalDownloaded, config))"
            case .totalUploaded:
                "\(config.symbolStyle.upload)Σ \(bytes(totalUploaded, config))"
            case .totalUsed:
                "Σ \(bytes(totalUsed, config))"
            }
            return MenuBarMetricText(metric: metric, text: text)
        }
    }

    private static func speed(_ bytes: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = SpeedFormatter.format(bytes, unit: config.speedUnit, decimals: config.decimalPrecision, fixedDecimals: true)
        return config.showUnits ? formatted : String(formatted.prefix(while: { $0 != " " }))
    }

    private static func bytes(_ value: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = ByteUnitFormatter.format(value, decimals: config.decimalPrecision, fixedDecimals: true)
        return config.showUnits ? formatted : String(formatted.prefix(while: { $0 != " " }))
    }

    private static func compactSpeed(_ value: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = SpeedFormatter.format(value, unit: config.speedUnit, decimals: config.decimalPrecision, fixedDecimals: true)
        let parts = formatted.split(separator: " ", maxSplits: 1)
        guard let number = parts.first else { return "0" }
        guard config.showUnits, parts.count == 2 else { return String(number) }
        let suffix = switch String(parts[1]) {
        case "B/s": "B"
        case "KB/s": "K"
        case "MB/s": "M"
        case "GB/s": "G"
        case "TB/s": "T"
        case "PB/s": "P"
        case "Mbps": "Mb"
        case "Gbps": "Gb"
        default: ""
        }
        return number + suffix
    }

    private static func compactBytes(_ value: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = ByteUnitFormatter.format(value, decimals: config.decimalPrecision, fixedDecimals: true)
        let parts = formatted.split(separator: " ", maxSplits: 1)
        guard let number = parts.first else { return "0" }
        guard config.showUnits, parts.count == 2 else { return String(number) }
        let suffix = String(parts[1].prefix(1))
        return number + suffix
    }

    private static func columnWidth(for metric: Metric, _ config: DisplayConfiguration) -> Int {
        let prefixExtra: Int
        switch metric {
        case .downloadSpeed, .totalDownloaded:
            prefixExtra = config.symbolStyle.download.count - 1
        case .uploadSpeed, .totalUploaded:
            prefixExtra = config.symbolStyle.upload.count - 1
        case .totalUsed:
            prefixExtra = 0
        }
        let totalExtra = metric == .totalDownloaded || metric == .totalUploaded ? 1 : 0
        return 8 + max(0, config.decimalPrecision - 1) + prefixExtra + totalExtra
    }
}
