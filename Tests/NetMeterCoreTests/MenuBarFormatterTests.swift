import XCTest
@testable import NetMeterCore

final class MenuBarFormatterTests: XCTestCase {
    func testDefaultShowsDownloadThenUpload() {
        let text = MenuBarFormatter.render(
            downloadBytesPerSecond: 2_500_000,
            uploadBytesPerSecond: 320_000,
            totalDownloaded: 0,
            totalUploaded: 0,
            configuration: .default
        )

        XCTAssertEqual(text, "↓ 2.4 MB/s ↑ 312.5 KB/s")
    }

    func testEnabledMetricOrderIsPreserved() {
        let configuration = DisplayConfiguration(
            order: [.uploadSpeed, .downloadSpeed, .totalUsed, .totalDownloaded, .totalUploaded],
            enabled: [.uploadSpeed, .totalUsed],
            speedUnit: .auto,
            decimalPrecision: 1,
            symbolStyle: .arrows,
            showUnits: true
        )
        let text = MenuBarFormatter.render(
            downloadBytesPerSecond: 2_500_000,
            uploadBytesPerSecond: 320_000,
            totalDownloaded: 1_000_000,
            totalUploaded: 500_000,
            configuration: configuration
        )

        XCTAssertEqual(text, "↑ 312.5 KB/s Σ 1.4 MB")
    }

    func testBinaryUnitsAndZeroSpeed() {
        let configuration = DisplayConfiguration(
            order: [.downloadSpeed, .uploadSpeed, .totalDownloaded, .totalUploaded, .totalUsed],
            enabled: [.downloadSpeed],
            speedUnit: .auto,
            decimalPrecision: 1,
            symbolStyle: .arrows,
            showUnits: true
        )
        let text = MenuBarFormatter.render(
            downloadBytesPerSecond: 0,
            uploadBytesPerSecond: 0,
            totalDownloaded: 0,
            totalUploaded: 0,
            configuration: configuration
        )

        XCTAssertEqual(text, "↓ 0 B/s")
        XCTAssertEqual(ByteUnitFormatter.format(1_048_576), "1 MB")
    }

    func testNoEnabledMetricsStillHasVisibleStatusItem() {
        let configuration = DisplayConfiguration(
            order: Metric.allCases,
            enabled: [],
            speedUnit: .auto,
            decimalPrecision: 1,
            symbolStyle: .arrows,
            showUnits: true
        )
        let text = MenuBarFormatter.render(
            downloadBytesPerSecond: 0,
            uploadBytesPerSecond: 0,
            totalDownloaded: 0,
            totalUploaded: 0,
            configuration: configuration
        )

        XCTAssertEqual(text, "NetMeter")
    }

    func testSymbolsAndUnitsCanBeChanged() {
        let configuration = DisplayConfiguration(
            order: Metric.allCases,
            enabled: [.downloadSpeed, .uploadSpeed],
            speedUnit: .megabits,
            decimalPrecision: 2,
            symbolStyle: .shortLabels,
            showUnits: false
        )

        let text = MenuBarFormatter.render(
            downloadBytesPerSecond: 125_000,
            uploadBytesPerSecond: 250_000,
            totalDownloaded: 0,
            totalUploaded: 0,
            configuration: configuration
        )

        XCTAssertEqual(text, "D: 1 U: 2")
    }
}
