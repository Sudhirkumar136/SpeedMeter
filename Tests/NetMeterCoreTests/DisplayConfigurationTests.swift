import XCTest
@testable import NetMeterCore

final class DisplayConfigurationTests: XCTestCase {
    func testOnlyFirstThreeEnabledMetricsRemainSelected() {
        var configuration = DisplayConfiguration.default
        configuration.order = [.totalUsed, .uploadSpeed, .downloadSpeed, .totalUploaded, .totalDownloaded]
        configuration.enabled = Set(Metric.allCases)

        XCTAssertEqual(configuration.normalized.enabled, [.totalUsed, .uploadSpeed, .downloadSpeed])
    }
}
