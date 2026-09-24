import XCTest
@testable import NetMeterCore

final class TrafficRateCalculatorTests: XCTestCase {
    func testOneSecondRateUsesByteCounterDifference() {
        var calculator = TrafficRateCalculator()
        _ = calculator.consume([counter(1_000_000, 500_000)], at: 10, expectedInterval: 1)

        let sample = calculator.consume([counter(2_048_576, 1_000_000)], at: 11, expectedInterval: 1)

        XCTAssertEqual(sample.downloadBytesPerSecond, 1_048_576)
        XCTAssertEqual(sample.uploadBytesPerSecond, 500_000)
        XCTAssertEqual(sample.delta, TrafficDelta(received: 1_048_576, sent: 500_000))
    }

    func testHalfSecondIntervalDoublesRateButNotUsage() {
        var calculator = TrafficRateCalculator()
        _ = calculator.consume([counter(0, 0)], at: 10, expectedInterval: 0.5)

        let sample = calculator.consume([counter(1_000, 500)], at: 10.5, expectedInterval: 0.5)

        XCTAssertEqual(sample.downloadBytesPerSecond, 2_000)
        XCTAssertEqual(sample.uploadBytesPerSecond, 1_000)
        XCTAssertEqual(sample.delta.received, 1_000)
    }

    func testLongGapRebaselinesWithoutFalseUsage() {
        var calculator = TrafficRateCalculator()
        _ = calculator.consume([counter(100, 100)], at: 10, expectedInterval: 1)

        let afterWake = calculator.consume([counter(1_000_000, 1_000_000)], at: 100, expectedInterval: 1)
        let next = calculator.consume([counter(1_000_100, 1_000_050)], at: 101, expectedInterval: 1)

        XCTAssertEqual(afterWake, .zero)
        XCTAssertEqual(next.delta, TrafficDelta(received: 100, sent: 50))
    }

    func testNearZeroElapsedTimeDoesNotOverflowRate() {
        var calculator = TrafficRateCalculator()
        _ = calculator.consume([counter(0, 0)], at: 10, expectedInterval: 1)

        let sample = calculator.consume([counter(UInt64.max, UInt64.max)], at: 10.000_001, expectedInterval: 1)

        XCTAssertEqual(sample, .zero)
    }

    private func counter(_ received: UInt64, _ sent: UInt64) -> InterfaceCounter {
        InterfaceCounter(name: "en0", received: received, sent: sent, isUp: true, isRunning: true)
    }
}
