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
        let parts = items(
            downloadBytesPerSecond: downloadBytesPerSecond,
            uploadBytesPerSecond: uploadBytesPerSecond,
            totalDownloaded: totalDownloaded,
            totalUploaded: totalUploaded,
            configuration: configuration
        )
        return parts.isEmpty ? "NetMeter" : parts.map(\.text).joined(separator: " ")
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
}
