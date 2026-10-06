import AppKit
import NetMeterCore
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var confirmResetToday = false
    @State private var confirmResetAll = false

    var body: some View {
        TabView(selection: $model.settingsTab) {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            menuBarTab
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
                .tag(SettingsTab.menuBar)
            usageTab
                .tabItem { Label("Usage", systemImage: "chart.bar") }
                .tag(SettingsTab.usage)
            UsageStatisticsView(model: model)
                .tabItem { Label("Statistics", systemImage: "chart.bar.xaxis") }
                .tag(SettingsTab.statistics)
            advancedTab
                .tabItem { Label("Advanced", systemImage: "network") }
                .tag(SettingsTab.advanced)
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(width: 640, height: 560)
        .alert("Reset today's statistics?", isPresented: $confirmResetToday) {
            Button("Reset Today", role: .destructive) { model.resetToday() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Today's download and upload totals will be cleared.")
        }
        .alert("Reset all statistics?", isPresented: $confirmResetAll) {
            Button("Reset All", role: .destructive) { model.resetAllStatistics() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All saved daily usage and the current session totals will be cleared.")
        }
        .alert("NetMeter", isPresented: Binding(
            get: { model.storageErrorMessage != nil || model.errorMessage != nil },
            set: { if !$0 { model.storageErrorMessage = nil; model.errorMessage = nil } }
        )) {
            Button("OK") { model.storageErrorMessage = nil; model.errorMessage = nil }
        } message: {
            Text(model.storageErrorMessage ?? model.errorMessage ?? "")
        }
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch NetMeter at login", isOn: Binding(
                    get: { model.launchAtLoginRequested },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if model.launchAtLoginRequested && model.launchAtLoginNeedsApproval {
                    LabeledContent("Status") {
                        Button("Approve in System Settings…") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                    }
                } else if model.launchAtLogin {
                    Text("NetMeter starts when you log in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Toggle("Start monitoring automatically", isOn: $model.settings.startMonitoringAutomatically)
            }
            Section("Monitoring") {
                Picker("Update interval", selection: $model.settings.updateInterval) {
                    Text("0.5 seconds").tag(0.5)
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }
                .pickerStyle(.menu)
                Text("Shorter intervals update the menu bar more often and use more energy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var menuBarTab: some View {
        Form {
            Section("Visible metrics") {
                Text("Choose up to three metrics. Drag a row to change their order.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(model.configuration.order, id: \.self) { metric in
                    HStack {
                        Toggle(metric.title, isOn: Binding(
                            get: { model.configuration.enabled.contains(metric) },
                            set: { isEnabled in
                                if isEnabled {
                                    if model.configuration.enabled.count < 3 {
                                        model.configuration.enabled.insert(metric)
                                    }
                                } else {
                                    model.configuration.enabled.remove(metric)
                                }
                            }
                        ))
                        .disabled(!model.configuration.enabled.contains(metric) && model.configuration.enabled.count >= 3)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .draggable(metric.rawValue)
                    .dropDestination(for: String.self) { items, _ in
                        guard let rawValue = items.first, let source = Metric(rawValue: rawValue) else {
                            return false
                        }
                        model.moveMetric(source, before: metric)
                        return true
                    }
                }
            }
            Section("Appearance") {
                Picker("Speed unit", selection: $model.configuration.speedUnit) {
                    ForEach(SpeedUnit.allCases, id: \.self) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                Picker("Decimal precision", selection: $model.configuration.decimalPrecision) {
                    Text("0 decimals").tag(0)
                    Text("1 decimal").tag(1)
                    Text("2 decimals").tag(2)
                }
                Picker("Symbols", selection: $model.configuration.symbolStyle) {
                    ForEach(SymbolStyle.allCases, id: \.self) { style in
                        Text(style.title).tag(style)
                    }
                }
                Toggle("Show units", isOn: $model.configuration.showUnits)
            }
            Section("Menu bar font") {
                Picker("Size", selection: $model.configuration.menuBarFontSize) {
                    ForEach(10...14, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
                Picker("Download weight", selection: $model.configuration.downloadFontWeight) {
                    ForEach(MenuBarFontWeight.allCases, id: \.self) { weight in
                        Text(weight.title).tag(weight)
                    }
                }
                Picker("Upload weight", selection: $model.configuration.uploadFontWeight) {
                    ForEach(MenuBarFontWeight.allCases, id: \.self) { weight in
                        Text(weight.title).tag(weight)
                    }
                }
                HStack {
                    Text("Preview")
                    Spacer()
                    Image(nsImage: FixedMeterImage.make(
                        title: model.compactMenuTitle,
                        columns: model.compactMenuColumns,
                        configuration: model.configuration
                    ))
                    .accessibilityLabel(model.menuTitle)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var usageTab: some View {
        Form {
            Section("Tracking") {
                Toggle("Track daily usage", isOn: $model.settings.trackDailyUsage)
                Toggle("Keep usage history", isOn: $model.settings.keepHistory)
                    .disabled(!model.settings.trackDailyUsage)
                Picker("History retention", selection: $model.settings.historyRetentionDays) {
                    Text("30 days").tag(Optional(30))
                    Text("90 days").tag(Optional(90))
                    Text("6 months").tag(Optional(180))
                    Text("1 year").tag(Optional(365))
                    Text("Unlimited").tag(Optional<Int>.none)
                }
                .disabled(!model.settings.keepHistory || !model.settings.trackDailyUsage)
            }
            Section("Reset") {
                Button("Reset Today's Statistics…") { confirmResetToday = true }
                Button("Reset All Statistics…") { confirmResetAll = true }
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    private var advancedTab: some View {
        Form {
            Section("Network interfaces") {
                Picker("Selection", selection: $model.settings.interfaceSelection) {
                    Text("Automatic").tag(InterfaceSelection.automatic)
                    Text("Manual").tag(InterfaceSelection.manual)
                }
                .pickerStyle(.segmented)
                Text("Automatic mode avoids counting the same VPN traffic on both a tunnel and its physical connection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.interfaces.isEmpty {
                    Text("No interfaces detected yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(model.interfaces, id: \.name) { interface in
                        HStack {
                            if model.settings.interfaceSelection == .manual {
                                Toggle(interface.name, isOn: Binding(
                                    get: { model.settings.selectedInterfaces.contains(interface.name) },
                                    set: { selected in
                                        if selected {
                                            model.settings.selectedInterfaces.insert(interface.name)
                                        } else {
                                            model.settings.selectedInterfaces.remove(interface.name)
                                        }
                                    }
                                ))
                            } else {
                                Text(interface.name)
                            }
                            Spacer()
                            Text(interface.isUp && interface.isRunning ? "Active" : "Inactive")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Stored data") {
                LabeledContent("Usage history", value: "~/Library/Application Support/NetMeter/usage.json")
                Text("Display and app settings are saved in your macOS Library preferences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Show usage data in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([UsageStore.defaultURL])
                }
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("NetMeter").font(.title.bold())
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                .foregroundStyle(.secondary)
            Text("A lightweight, native network speed and usage monitor for the macOS menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 330)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
