import Foundation
import XCTest
@testable import NetMeterCore

final class UsageLedgerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testDailyAggregationAcrossPeriods() {
        var ledger = UsageLedger()
        ledger.record(TrafficDelta(received: 100, sent: 10), on: date(2026, 8, 31), calendar: calendar)
        ledger.record(TrafficDelta(received: 200, sent: 20), on: date(2026, 9, 17), calendar: calendar)
        ledger.record(TrafficDelta(received: 300, sent: 30), on: date(2026, 9, 18), calendar: calendar)
        ledger.record(TrafficDelta(received: 400, sent: 40), on: date(2026, 9, 23), calendar: calendar)
        ledger.record(TrafficDelta(received: 500, sent: 50), on: date(2026, 9, 24), calendar: calendar)
        ledger.record(TrafficDelta(received: 100, sent: 5), on: date(2026, 9, 24), calendar: calendar)

        let today = date(2026, 9, 24)
        XCTAssertEqual(ledger.totals(for: .today, relativeTo: today, calendar: calendar), TrafficTotals(downloaded: 600, uploaded: 55))
        XCTAssertEqual(ledger.totals(for: .yesterday, relativeTo: today, calendar: calendar), TrafficTotals(downloaded: 400, uploaded: 40))
        XCTAssertEqual(ledger.totals(for: .lastSevenDays, relativeTo: today, calendar: calendar), TrafficTotals(downloaded: 1_300, uploaded: 125))
        XCTAssertEqual(ledger.totals(for: .thisMonth, relativeTo: today, calendar: calendar), TrafficTotals(downloaded: 1_500, uploaded: 145))
        XCTAssertEqual(ledger.totals(for: .previousMonth, relativeTo: today, calendar: calendar), TrafficTotals(downloaded: 100, uploaded: 10))
    }

    func testResetTodayKeepsEarlierDaysAndPruneRemovesOldDays() {
        var ledger = UsageLedger()
        ledger.record(TrafficDelta(received: 100, sent: 10), on: date(2026, 9, 1), calendar: calendar)
        ledger.record(TrafficDelta(received: 200, sent: 20), on: date(2026, 9, 23), calendar: calendar)
        ledger.record(TrafficDelta(received: 300, sent: 30), on: date(2026, 9, 24), calendar: calendar)

        ledger.resetToday(relativeTo: date(2026, 9, 24), calendar: calendar)
        XCTAssertEqual(ledger.totals(for: .today, relativeTo: date(2026, 9, 24), calendar: calendar), .zero)
        ledger.prune(keepingLast: 7, relativeTo: date(2026, 9, 24), calendar: calendar)
        XCTAssertEqual(ledger.dailyRows.map(\.day), ["2026-09-23"])
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
