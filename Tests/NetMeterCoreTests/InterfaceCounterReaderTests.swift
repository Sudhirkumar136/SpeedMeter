import XCTest
@testable import NetMeterCore

final class InterfaceCounterReaderTests: XCTestCase {
    func testNativeReaderReturnsUniqueInterfaceNames() throws {
        let counters = try InterfaceCounterReader.read()

        XCTAssertFalse(counters.isEmpty)
        XCTAssertEqual(Set(counters.map(\.name)).count, counters.count)
        XCTAssertTrue(counters.contains { $0.name.hasPrefix("en") || $0.name.hasPrefix("lo") })
    }
}
