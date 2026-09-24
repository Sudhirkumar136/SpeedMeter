import XCTest
@testable import NetMeterCore

final class TrafficDeltaCalculatorTests: XCTestCase {
    func testFirstSampleIsBaselineAndSecondIsDelta() {
        var calculator = TrafficDeltaCalculator()
        let first = calculator.consume([
            InterfaceCounter(name: "en0", received: 1_000, sent: 2_000, isUp: true, isRunning: true)
        ])
        let second = calculator.consume([
            InterfaceCounter(name: "en0", received: 1_400, sent: 2_250, isUp: true, isRunning: true)
        ])

        XCTAssertEqual(first, TrafficDelta(received: 0, sent: 0))
        XCTAssertEqual(second, TrafficDelta(received: 400, sent: 250))
    }

    func testTunnelIsExcludedWhenPhysicalInterfaceIsActive() {
        var calculator = TrafficDeltaCalculator()
        _ = calculator.consume([
            InterfaceCounter(name: "en0", received: 1_000, sent: 1_000, isUp: true, isRunning: true),
            InterfaceCounter(name: "utun5", received: 500, sent: 500, isUp: true, isRunning: true)
        ])
        let delta = calculator.consume([
            InterfaceCounter(name: "en0", received: 1_200, sent: 1_100, isUp: true, isRunning: true),
            InterfaceCounter(name: "utun5", received: 700, sent: 600, isUp: true, isRunning: true)
        ])

        XCTAssertEqual(delta, TrafficDelta(received: 200, sent: 100))
    }

    func testTunnelIsUsedWhenNoPhysicalInterfaceIsActive() {
        var calculator = TrafficDeltaCalculator()
        _ = calculator.consume([
            InterfaceCounter(name: "utun5", received: 500, sent: 500, isUp: true, isRunning: true)
        ])
        let delta = calculator.consume([
            InterfaceCounter(name: "utun5", received: 700, sent: 600, isUp: true, isRunning: true)
        ])

        XCTAssertEqual(delta, TrafficDelta(received: 200, sent: 100))
    }

    func testNewInterfaceAndResetCounterDoNotCreateFalseSpike() {
        var calculator = TrafficDeltaCalculator()
        _ = calculator.consume([
            InterfaceCounter(name: "en0", received: 5_000, sent: 5_000, isUp: true, isRunning: true)
        ])
        let switched = calculator.consume([
            InterfaceCounter(name: "en1", received: 8_000, sent: 8_000, isUp: true, isRunning: true)
        ])
        let reset = calculator.consume([
            InterfaceCounter(name: "en1", received: 100, sent: 100, isUp: true, isRunning: true)
        ])

        XCTAssertEqual(switched, TrafficDelta(received: 0, sent: 0))
        XCTAssertEqual(reset, TrafficDelta(received: 0, sent: 0))
    }

    func testInactiveAndLoopbackInterfacesAreExcluded() {
        var calculator = TrafficDeltaCalculator()
        _ = calculator.consume([
            InterfaceCounter(name: "lo0", received: 100, sent: 100, isUp: true, isRunning: true),
            InterfaceCounter(name: "en0", received: 100, sent: 100, isUp: true, isRunning: false)
        ])
        let delta = calculator.consume([
            InterfaceCounter(name: "lo0", received: 200, sent: 200, isUp: true, isRunning: true),
            InterfaceCounter(name: "en0", received: 200, sent: 200, isUp: true, isRunning: false)
        ])

        XCTAssertEqual(delta, TrafficDelta(received: 0, sent: 0))
    }

    func testManualModeCountsExactlyTheSelectedInterfaces() {
        var calculator = TrafficDeltaCalculator()
        let first = [
            InterfaceCounter(name: "en0", received: 100, sent: 100, isUp: true, isRunning: true),
            InterfaceCounter(name: "utun5", received: 100, sent: 100, isUp: true, isRunning: true),
            InterfaceCounter(name: "awdl0", received: 100, sent: 100, isUp: true, isRunning: true)
        ]
        _ = calculator.consume(first, mode: .manual)
        let second = first.map {
            InterfaceCounter(name: $0.name, received: 200, sent: 150, isUp: true, isRunning: true)
        }

        XCTAssertEqual(calculator.consume(second, mode: .manual), TrafficDelta(received: 300, sent: 150))
    }

    func testInterfaceBecomingActiveStartsWithFreshBaseline() {
        var calculator = TrafficDeltaCalculator()
        _ = calculator.consume([
            InterfaceCounter(name: "en0", received: 1_000, sent: 1_000, isUp: true, isRunning: false)
        ])

        let activated = calculator.consume([
            InterfaceCounter(name: "en0", received: 2_000, sent: 2_000, isUp: true, isRunning: true)
        ])

        XCTAssertEqual(activated, TrafficDelta(received: 0, sent: 0))
    }
}
