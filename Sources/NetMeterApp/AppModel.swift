import AppKit
import NetMeterCore
import Observation
import ServiceManagement

enum SettingsTab: Hashable {
    case general
    case menuBar
    case usage
    case advanced
    case about
}

@MainActor
@Observable
final class AppModel {
    var settingsTab: SettingsTab = .general
    var configuration: DisplayConfiguration {
        didSet { preferences.save(configuration: configuration) }
    }
    var settings: AppSettings {
        didSet {
            preferences.save(settings: settings)
            if settings != oldValue { restartMonitoring() }
        }
    }
    private(set) var sample = TrafficSample.zero
    private(set) var session = TrafficTotals.zero
    private(set) var cumulative = TrafficTotals.zero
    private(set) var ledger = UsageLedger()
    private(set) var interfaces: [InterfaceCounter] = []
    private(set) var isMonitoring = false
    private(set) var launchAtLogin = false
    var errorMessage: String?

    @ObservationIgnored
    private let preferences: PreferencesStore
    @ObservationIgnored
    private let usageStore = UsageStore()
    @ObservationIgnored
    private let monitor = NetworkMonitor()
    @ObservationIgnored
    private var monitoringTask: Task<Void, Never>?
    @ObservationIgnored
    private var usageSaveTask: Task<Void, Never>?
    @ObservationIgnored
    private var ticksSinceSave = 0
    @ObservationIgnored
    private var resumeAfterWake = false

    var menuTitle: String {
        guard isMonitoring else { return "⏸ NetMeter" }
        let items = menuItems
        return items.isEmpty ? "NetMeter" : items.map(\.text).joined(separator: " ")
    }

    var menuItems: [MenuBarMetricText] {
        MenuBarFormatter.items(
            downloadBytesPerSecond: sample.downloadBytesPerSecond,
            uploadBytesPerSecond: sample.uploadBytesPerSecond,
            totalDownloaded: cumulative.downloaded,
            totalUploaded: cumulative.uploaded,
            configuration: configuration
        )
    }

    init(preferences: PreferencesStore = PreferencesStore()) {
        self.preferences = preferences
        self.configuration = preferences.loadConfiguration()
        self.settings = preferences.loadSettings()
        self.cumulative = preferences.loadTotals()
        self.launchAtLogin = SMAppService.mainApp.status == .enabled

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        Task { [weak self] in
            await self?.loadUsageAndStart()
        }
    }

    private func loadUsageAndStart() async {
        ledger = await usageStore.load()
        if settings.startMonitoringAutomatically { startMonitoring() }
    }

    func startMonitoring() {
        guard monitoringTask == nil else { return }
        isMonitoring = true
        monitoringTask = Task { [weak self] in
            guard let monitor = self?.monitor else { return }
            await monitor.reset()
            while let self, !Task.isCancelled {
                let currentSettings = self.settings
                do {
                    let reading = try await monitor.read(settings: currentSettings)
                    if Task.isCancelled { break }
                    self.apply(reading)
                    self.errorMessage = nil
                } catch {
                    self.sample = .zero
                    self.errorMessage = "Network statistics unavailable: \(error.localizedDescription)"
                }
                try? await Task.sleep(for: .seconds(currentSettings.updateInterval))
            }
        }
    }

    func pauseMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        sample = .zero
        saveUsage()
    }

    func toggleMonitoring() {
        isMonitoring ? pauseMonitoring() : startMonitoring()
    }

    private func restartMonitoring() {
        guard isMonitoring else { return }
        pauseMonitoring()
        startMonitoring()
    }

    private func apply(_ reading: NetworkReading) {
        sample = reading.sample
        interfaces = reading.interfaces
        session.add(reading.sample.delta)
        cumulative.add(reading.sample.delta)
        if settings.trackDailyUsage {
            ledger.record(reading.sample.delta, on: Date())
            if settings.keepHistory {
                if let retention = settings.historyRetentionDays {
                    ledger.prune(keepingLast: retention, relativeTo: Date())
                }
            } else {
                ledger.prune(keepingLast: 1, relativeTo: Date())
            }
        }
        ticksSinceSave += 1
        if ticksSinceSave >= 15 {
            ticksSinceSave = 0
            saveUsage()
        }
    }

    func usage(for period: UsagePeriod) -> TrafficTotals {
        ledger.totals(for: period, relativeTo: Date())
    }

    func resetSession() {
        session = .zero
    }

    func resetToday() {
        ledger.resetToday(relativeTo: Date())
        saveUsage()
    }

    func resetAllStatistics() {
        ledger.resetAll()
        session = .zero
        cumulative = .zero
        saveUsage()
    }

    func moveMetric(_ source: Metric, before destination: Metric) {
        guard source != destination,
              let from = configuration.order.firstIndex(of: source),
              let to = configuration.order.firstIndex(of: destination)
        else { return }
        var order = configuration.order
        order.remove(at: from)
        order.insert(source, at: from < to ? to - 1 : to)
        configuration.order = order
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Could not change Launch at Login: \(error.localizedDescription)"
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func quit() {
        monitoringTask?.cancel()
        preferences.save(totals: cumulative)
        let previousSave = usageSaveTask
        let snapshot = ledger
        Task {
            await previousSave?.value
            try? await usageStore.save(snapshot)
            NSApp.terminate(nil)
        }
    }

    private func saveUsage() {
        preferences.save(totals: cumulative)
        let snapshot = ledger
        let previousSave = usageSaveTask
        usageSaveTask = Task {
            await previousSave?.value
            try? await usageStore.save(snapshot)
        }
    }

    @objc private func handleSleep() {
        resumeAfterWake = isMonitoring
        if isMonitoring { pauseMonitoring() }
        saveUsage()
    }

    @objc private func handleWake() {
        sample = .zero
        if resumeAfterWake { startMonitoring() }
        resumeAfterWake = false
    }
}
