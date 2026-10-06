import XCTest
@testable import NetMeterCore

final class DisplayConfigurationTests: XCTestCase {
    func testOnlyFirstThreeEnabledMetricsRemainSelected() {
        var configuration = DisplayConfiguration.default
        configuration.order = [.totalUsed, .uploadSpeed, .downloadSpeed, .totalUploaded, .totalDownloaded]
        configuration.enabled = Set(Metric.allCases)

        XCTAssertEqual(configuration.normalized.enabled, [.totalUsed, .uploadSpeed, .downloadSpeed])
    }

    func testFontPreferencesNormalizeToSupportedSizes() {
        var configuration = DisplayConfiguration.default
        configuration.menuBarFontSize = 99
        configuration.downloadFontWeight = .bold
        configuration.uploadFontWeight = .medium

        XCTAssertEqual(configuration.normalized.menuBarFontSize, 14)
        XCTAssertEqual(configuration.normalized.downloadFontWeight, .bold)
        XCTAssertEqual(configuration.normalized.uploadFontWeight, .medium)
    }

    func testOlderConfigurationDecodesWithDefaultFontPreferences() throws {
        let legacy = """
        {"order":["downloadSpeed","uploadSpeed","totalDownloaded","totalUploaded","totalUsed"],"enabled":["downloadSpeed","uploadSpeed"],"speedUnit":"auto","decimalPrecision":1,"symbolStyle":"arrows","showUnits":true}
        """
        let configuration = try JSONDecoder().decode(DisplayConfiguration.self, from: Data(legacy.utf8))

        XCTAssertEqual(configuration.menuBarFontSize, 12)
        XCTAssertEqual(configuration.downloadFontWeight, .regular)
        XCTAssertEqual(configuration.uploadFontWeight, .regular)
    }
}
