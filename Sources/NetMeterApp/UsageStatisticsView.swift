import Charts
import NetMeterCore
import SwiftUI

struct UsageStatisticsView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Usage Statistics")
                    .font(.largeTitle.bold())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryCard(.today)
                    summaryCard(.yesterday)
                    summaryCard(.lastSevenDays)
                    summaryCard(.thisMonth)
                }

                GroupBox("Daily usage") {
                    if model.ledger.dailyRows.isEmpty {
                        ContentUnavailableView("No Usage Yet", systemImage: "chart.bar", description: Text("Daily usage appears after monitoring begins."))
                            .frame(height: 180)
                    } else {
                        Chart {
                            ForEach(Array(model.ledger.dailyRows.prefix(14).reversed())) { row in
                                BarMark(
                                    x: .value("Day", row.day),
                                    y: .value("Bytes", row.totals.downloaded)
                                )
                                .foregroundStyle(by: .value("Direction", "Download"))
                                BarMark(
                                    x: .value("Day", row.day),
                                    y: .value("Bytes", row.totals.uploaded)
                                )
                                .foregroundStyle(by: .value("Direction", "Upload"))
                            }
                        }
                        .frame(height: 220)
                        .padding(.top, 8)
                    }
                }

                GroupBox("History") {
                    if model.ledger.dailyRows.isEmpty {
                        Text("No saved daily usage.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(model.ledger.dailyRows) { row in
                                HStack {
                                    Text(row.day).fontWeight(.medium)
                                    Spacer()
                                    Text("↓ \(ByteUnitFormatter.format(row.totals.downloaded))")
                                    Text("↑ \(ByteUnitFormatter.format(row.totals.uploaded))")
                                    Text("Total \(ByteUnitFormatter.format(row.totals.total))")
                                        .fontWeight(.semibold)
                                }
                                .monospacedDigit()
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func summaryCard(_ period: UsagePeriod) -> some View {
        let totals = model.usage(for: period)
        return VStack(alignment: .leading, spacing: 8) {
            Text(period.title).font(.headline)
            Text(ByteUnitFormatter.format(totals.total))
                .font(.title2.bold())
                .monospacedDigit()
            HStack {
                Text("↓ \(ByteUnitFormatter.format(totals.downloaded))")
                Spacer()
                Text("↑ \(ByteUnitFormatter.format(totals.uploaded))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}
