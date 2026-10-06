import Foundation
import XCTest
@testable import NetMeterCore

final class UsageCSVExporterTests: XCTestCase {
    func testExportsNewestFirstWithExactByteCountsAndLineEndings() {
        let ledger = UsageLedger(days: [
            "2026-10-05": TrafficTotals(downloaded: 1024, uploaded: 25),
            "2026-10-06": TrafficTotals(downloaded: 2048, uploaded: 50)
        ])

        XCTAssertEqual(
            UsageCSVExporter.render(ledger),
            "Date,Downloaded Bytes,Uploaded Bytes,Total Bytes\r\n" +
            "2026-10-06,2048,50,2098\r\n" +
            "2026-10-05,1024,25,1049\r\n"
        )
    }

    func testEmptyLedgerExportsHeaderOnly() {
        XCTAssertEqual(
            UsageCSVExporter.render(UsageLedger()),
            "Date,Downloaded Bytes,Uploaded Bytes,Total Bytes\r\n"
        )
    }

    func testEscapesUnexpectedDateTextForSpreadsheetSafety() {
        let ledger = UsageLedger(days: [
            "=SUM(1,2)": TrafficTotals(downloaded: 1, uploaded: 2)
        ])

        XCTAssertEqual(
            UsageCSVExporter.render(ledger),
            "Date,Downloaded Bytes,Uploaded Bytes,Total Bytes\r\n" +
            "\"'=SUM(1,2)\",1,2,3\r\n"
        )
    }
}
