import AppKit
import NetMeterCore
import SwiftUI

struct MenuBarView: View {
    let model: AppModel
    @Environment(\.openSettings) private var openSettings
    @State private var confirmResetSession = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("NetMeter").font(.headline)
                Spacer()
                if !model.isMonitoring {
                    Text("Paused").foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                speedCard("Download", symbol: "arrow.down", bytes: model.sample.downloadBytesPerSecond)
                speedCard("Upload", symbol: "arrow.up", bytes: model.sample.uploadBytesPerSecond)
            }

            Divider()
            usageSection("Session", totals: model.session)
            usageSection("Today", totals: model.usage(for: .today))
            Divider()

            VStack(spacing: 2) {
                action("Usage Statistics", systemImage: "chart.bar.xaxis") {
                    model.settingsTab = .statistics
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                action("Settings…", systemImage: "gearshape") {
                    model.settingsTab = .general
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                action("Font Style…", systemImage: "textformat") {
                    model.settingsTab = .fontStyle
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                action(model.isMonitoring ? "Pause Monitoring" : "Resume Monitoring", systemImage: model.isMonitoring ? "pause" : "play") {
                    model.toggleMonitoring()
                }
                action("Reset Session Statistics", systemImage: "arrow.counterclockwise") {
                    confirmResetSession = true
                }
                action("About NetMeter", systemImage: "info.circle") {
                    model.settingsTab = .about
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                action("Quit NetMeter", systemImage: "power") {
                    model.quit()
                }
            }
            if let error = model.storageErrorMessage ?? model.errorMessage ?? model.monitoringErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 308)
        .confirmationDialog("Reset session statistics?", isPresented: $confirmResetSession) {
            Button("Reset Session", role: .destructive) { model.resetSession() }
        } message: {
            Text("The current session's download and upload totals will be cleared.")
        }
    }

    private func speedCard(_ title: String, symbol: String, bytes: UInt64) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(SpeedFormatter.format(bytes, unit: model.configuration.speedUnit, decimals: model.configuration.decimalPrecision))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func usageSection(_ title: String, totals: TrafficTotals) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold))
            HStack {
                Text("↓ \(ByteUnitFormatter.format(totals.downloaded))")
                Spacer()
                Text("↑ \(ByteUnitFormatter.format(totals.uploaded))")
            }
            .foregroundStyle(.secondary)
            .monospacedDigit()
            Text("Total \(ByteUnitFormatter.format(totals.total))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func action(_ title: String, systemImage: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
