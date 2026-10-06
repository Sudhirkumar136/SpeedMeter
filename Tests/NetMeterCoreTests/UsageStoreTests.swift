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
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("usage.json")
        try Data("not json".utf8).write(to: url)

        let store = UsageStore(url: url)
        let loaded = await store.load()
        let recovered = await store.recoveredCorruptFileURL

        XCTAssertEqual(loaded, UsageLedger())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let backup = try XCTUnwrap(recovered)
        XCTAssertEqual(try Data(contentsOf: backup), Data("not json".utf8))
    }
}
