import Foundation
import XCTest
@testable import NetMeterCore

final class PreferencesStoreTests: XCTestCase {
    func testConfigurationAndTotalsSurviveStoreRecreation() {
        let suiteName = "NetMeterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let configuration = DisplayConfiguration(
            order: [.uploadSpeed, .downloadSpeed, .totalUsed, .totalDownloaded, .totalUploaded],
            enabled: [.uploadSpeed, .totalUsed],
            speedUnit: .megabytes,
            decimalPrecision: 2,
            symbolStyle: .thinArrows,
            showUnits: false
        )

        let writer = PreferencesStore(defaults: defaults)
        writer.save(configuration: configuration)
        writer.save(totals: TrafficTotals(downloaded: 1_234, uploaded: 567))
        let reader = PreferencesStore(defaults: defaults)

        XCTAssertEqual(reader.loadConfiguration(), configuration)
        XCTAssertEqual(reader.loadTotals(), TrafficTotals(downloaded: 1_234, uploaded: 567))
    }

    func testInvalidStoredConfigurationFallsBackToDefault() {
        let suiteName = "NetMeterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("invalid".utf8), forKey: "displayConfiguration")

        XCTAssertEqual(PreferencesStore(defaults: defaults).loadConfiguration(), .default)
    }

    func testTrafficTotalsSaturateRatherThanWrap() {
        var totals = TrafficTotals(downloaded: UInt64.max - 1, uploaded: 10)

        totals.add(TrafficDelta(received: 100, sent: UInt64.max))

        XCTAssertEqual(totals.downloaded, UInt64.max)
        XCTAssertEqual(totals.uploaded, UInt64.max)
        XCTAssertEqual(totals.total, UInt64.max)
    }
}
