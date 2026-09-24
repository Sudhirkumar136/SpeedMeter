import Foundation
import XCTest
@testable import NetMeterCore

final class AppSettingsTests: XCTestCase {
    func testGeneralAndInterfaceSettingsPersist() {
        let suiteName = "NetMeterSettingsTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create test defaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PreferencesStore(defaults: defaults)
        var settings = AppSettings.default
        settings.updateInterval = 2
        settings.startMonitoringAutomatically = false
        settings.trackDailyUsage = false
        settings.keepHistory = true
        settings.historyRetentionDays = 90
        settings.interfaceSelection = .manual
        settings.selectedInterfaces = ["en0", "utun1"]

        store.save(settings: settings)

        XCTAssertEqual(PreferencesStore(defaults: defaults).loadSettings(), settings)
    }

    func testInvalidUpdateIntervalNormalizesToOneSecond() {
        var settings = AppSettings.default
        settings.updateInterval = 0.01

        XCTAssertEqual(settings.normalized.updateInterval, 1)
    }
}
