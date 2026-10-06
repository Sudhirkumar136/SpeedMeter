import Charts
import NetMeterCore
import SwiftUI

struct UsageStatisticsView: View {
    let model: AppModel
    @State private var exportDocument: UsageCSVDocument?
    @State private var showExporter = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Usage Statistics")
                        .font(.title2.bold())
                    Text("Saved daily totals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    exportDocument = UsageCSVDocument(contents: UsageCSVExporter.render(model.ledger))
                    showExporter = true
                } label: {
                    Label("Export CSV…", systemImage: "square.and.arrow.up")
                }
                .disabled(model.ledger.dailyRows.isEmpty)
                .help("Export all saved daily totals as exact byte counts")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        summaryCard(.today)
                        summaryCard(.yesterday)
                        summaryCard(.lastSevenDays)
                        summaryCard(.thisMonth)
                    }
                    summaryCard(.previousMonth)

                    GroupBox("Daily usage") {
                        if model.ledger.dailyRows.isEmpty {
                            ContentUnavailableView(
                                "No Usage Yet", systemImage: "chart.bar",
                                description: Text("Daily usage appears after monitoring begins.")
                            )
                            .frame(height: 180)
                        } else {
                            dailyUsageChart
                                .frame(height: 180)
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
                                    VStack(spacing: 4) {
                                        HStack {
                                            Text(row.day).fontWeight(.medium)
                                            Spacer()
                                            Text("Total \(ByteUnitFormatter.format(row.totals.total))")
                                                .fontWeight(.semibold)
                                        }
                                        HStack {
                                            Text("↓ \(ByteUnitFormatter.format(row.totals.downloaded))")
                                            Spacer()
                                            Text("↑ \(ByteUnitFormatter.format(row.totals.uploaded))")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    .monospacedDigit()
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "NetMeter-Usage"
        ) { result in
            if case .failure(let error) = result {
                model.errorMessage = "Could not export usage statistics: \(error.localizedDescription)"
            }
        }
    }

    private var dailyUsageChart: some View {
        Chart {
            ForEach(Array(model.ledger.dailyRows.prefix(14).reversed())) { row in
                BarMark(x: .value("Day", row.day), y: .value("Bytes", row.totals.downloaded))
                    .foregroundStyle(by: .value("Direction", "Download"))
                BarMark(x: .value("Day", row.day), y: .value("Bytes", row.totals.uploaded))
                    .foregroundStyle(by: .value("Direction", "Upload"))
            }
        }
        .chartForegroundStyleScale(["Download": Color.blue, "Upload": Color.orange])
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel() }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    Text(byteAxisLabel(value.as(Double.self) ?? 0))
                }
            }
        }
    }

    private func byteAxisLabel(_ value: Double) -> String {
        guard value.isFinite, value > 0 else { return "0 B" }
        let bytes = value >= Double(UInt64.max) ? UInt64.max : UInt64(value)
        return ByteUnitFormatter.format(bytes, decimals: 0)
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
