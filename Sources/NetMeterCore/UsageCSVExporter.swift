import Foundation

public enum UsageCSVExporter {
    public static func render(_ ledger: UsageLedger) -> String {
        let header = "Date,Downloaded Bytes,Uploaded Bytes,Total Bytes\r\n"
        return ledger.dailyRows.reduce(into: header) { output, row in
            output += "\(csvDate(row.day)),\(row.totals.downloaded),\(row.totals.uploaded),\(row.totals.total)\r\n"
        }
    }

    private static func csvDate(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = if let first = trimmed.first, "=+-@".contains(first) {
            "'" + value
        } else {
            value
        }
        guard safe.contains(where: { ",\"\r\n".contains($0) }) else { return safe }
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
