import Foundation
import XCTest
@testable import NetMeterCore

final class UsageStoreTests: XCTestCase {
    func testLedgerSurvivesStoreRecreation() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("usage.json")
        var ledger = UsageLedger()
        ledger.record(TrafficDelta(received: 123, sent: 45), on: Date(timeIntervalSince1970: 1_000))

        try await UsageStore(url: url).save(ledger)
        let restored = await UsageStore(url: url).load()

        XCTAssertEqual(restored, ledger)
    }

    func testCorruptFileLoadsEmptyLedger() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)

        let loaded = await UsageStore(url: url).load()
        XCTAssertEqual(loaded, UsageLedger())
    }
}
