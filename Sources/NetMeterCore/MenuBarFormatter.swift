import Foundation

public enum ByteUnitFormatter {
    public static func format(_ bytes: UInt64, decimals: Int = 1) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var index = 0
        while value >= 1_024 && index < units.count - 1 {
            value /= 1_024
            index += 1
        }
        return "\(formatNumber(value, decimals: index == 0 ? 0 : decimals)) \(units[index])"
    }
}

public enum SpeedFormatter {
    public static func format(_ bytesPerSecond: UInt64, unit: SpeedUnit, decimals: Int) -> String {
        let value = Double(bytesPerSecond)
        let scaled: Double
        let suffix: String
        switch unit {
        case .auto:
            return "\(ByteUnitFormatter.format(bytesPerSecond, decimals: decimals))/s"
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
        return "\(formatNumber(scaled, decimals: decimals)) \(suffix)"
    }
}

private func formatNumber(_ value: Double, decimals: Int) -> String {
    let precision = min(2, max(0, decimals))
    var formatted = String(format: "%.*f", locale: Locale(identifier: "en_US_POSIX"), precision, value)
    guard formatted.contains(".") else { return formatted }
    while formatted.last == "0" { formatted.removeLast() }
    if formatted.last == "." { formatted.removeLast() }
    return formatted
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
        let total = totalDownloaded.addingReportingOverflow(totalUploaded)
        let totalUsed = total.overflow ? UInt64.max : total.partialValue
        let parts = config.order.filter { config.enabled.contains($0) }.map { metric in
            switch metric {
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
        }
        return parts.isEmpty ? "NetMeter" : parts.joined(separator: " ")
    }

    private static func speed(_ bytes: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = SpeedFormatter.format(bytes, unit: config.speedUnit, decimals: config.decimalPrecision)
        return config.showUnits ? formatted : String(formatted.prefix(while: { $0 != " " }))
    }

    private static func bytes(_ value: UInt64, _ config: DisplayConfiguration) -> String {
        let formatted = ByteUnitFormatter.format(value, decimals: config.decimalPrecision)
        return config.showUnits ? formatted : String(formatted.prefix(while: { $0 != " " }))
    }
}
