import XCTest
@testable import NetMeterCore

final class SpeedFormatterTests: XCTestCase {
    func testAutoUsesBinaryByteScale() {
        XCTAssertEqual(SpeedFormatter.format(0, unit: .auto, decimals: 1), "0 B/s")
        XCTAssertEqual(SpeedFormatter.format(950, unit: .auto, decimals: 1), "950 B/s")
        XCTAssertEqual(SpeedFormatter.format(1_331, unit: .auto, decimals: 1), "1.3 KB/s")
        XCTAssertEqual(SpeedFormatter.format(2_516_582, unit: .auto, decimals: 1), "2.4 MB/s")
    }

    func testFixedMegabitsAndPrecision() {
        XCTAssertEqual(SpeedFormatter.format(125_000, unit: .megabits, decimals: 0), "1 Mbps")
        XCTAssertEqual(SpeedFormatter.format(156_250, unit: .megabits, decimals: 2), "1.25 Mbps")
    }

    func testDataUsageUsesBinaryScale() {
        XCTAssertEqual(ByteUnitFormatter.format(1_024), "1 KB")
        XCTAssertEqual(ByteUnitFormatter.format(1_073_741_824), "1 GB")
    }
}
