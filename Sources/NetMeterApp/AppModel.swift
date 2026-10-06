import AppKit
import NetMeterCore
import Observation
import ServiceManagement

enum SettingsTab: Hashable {
    case general
    case menuBar
    case usage
    case statistics
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
    private(set) var launchAtLoginRequested = true
    private(set) var launchAtLoginNeedsApproval = false
    var errorMessage: String?
    var storageErrorMessage: String?
    private(set) var monitoringErrorMessage: String?

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
    @ObservationIgnored
    private var loginPromptShown = false

    var menuTitle: String {
        guard isMonitoring else { return "⏸ NetMeter" }
        let items = menuItems
        return items.isEmpty ? "NetMeter" : items.map(\.text).joined(separator: " ")
    }

    var compactMenuTitle: String {
        guard isMonitoring else { return "⏸ Paused" }
        return MenuBarFormatter.render(
            downloadBytesPerSecond: sample.downloadBytesPerSecond,
            uploadBytesPerSecond: sample.uploadBytesPerSecond,
            totalDownloaded: cumulative.downloaded,
            totalUploaded: cumulative.uploaded,
            configuration: configuration
        )
    }

    var compactMenuColumns: [MenuBarColumn] {
        guard isMonitoring else { return [] }
        return MenuBarFormatter.columns(
            downloadBytesPerSecond: sample.downloadBytesPerSecond,
            uploadBytesPerSecond: sample.uploadBytesPerSecond,
            totalDownloaded: cumulative.downloaded,
            totalUploaded: cumulative.uploaded,
            configuration: configuration
        )
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
        self.launchAtLoginRequested = preferences.loadLaunchAtLoginRequested()
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.launchAtLoginNeedsApproval = SMAppService.mainApp.status == .requiresApproval

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshLaunchAtLoginStatus),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        Task { [weak self] in
            await self?.loadUsageAndStart()
            await self?.configureLaunchAtLogin()
        }
    }

    private func loadUsageAndStart() async {
        ledger = await usageStore.load()
        if let recovered = await usageStore.recoveredCorruptFileURL {
            errorMessage = "An unreadable usage file was preserved at \(recovered.path). A new history has started."
        }
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
                    self.monitoringErrorMessage = nil
                } catch {
                    self.sample = .zero
                    self.monitoringErrorMessage = "Network statistics unavailable: \(error.localizedDescription)"
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
        if enabled && SMAppService.mainApp.status == .notFound {
            errorMessage = "macOS could not find NetMeter as a login item. Reinstall the app in Applications and try again."
            return
        }
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status != .notRegistered {
                    try SMAppService.mainApp.unregister()
                }
            }
            preferences.saveLaunchAtLoginRequested(enabled)
            launchAtLoginRequested = enabled
        } catch {
            errorMessage = "Could not change Launch at Login: \(error.localizedDescription)"
        }
        refreshLaunchAtLoginStatus()
        if enabled && launchAtLoginNeedsApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    @objc func refreshLaunchAtLoginStatus() {
        let status = SMAppService.mainApp.status
        launchAtLogin = status == .enabled
        launchAtLoginNeedsApproval = status == .requiresApproval
    }

    private func configureLaunchAtLogin() async {
        guard launchAtLoginRequested else { return }
        if SMAppService.mainApp.status == .notFound {
            errorMessage = "macOS could not find NetMeter as a login item. Reinstall the app in Applications and try again."
            return
        }
        if SMAppService.mainApp.status == .notRegistered {
            do {
                try SMAppService.mainApp.register()
            } catch {
                errorMessage = "Could not enable Launch at Login: \(error.localizedDescription)"
            }
        }
        refreshLaunchAtLoginStatus()
        guard launchAtLoginNeedsApproval, !loginPromptShown else { return }
        loginPromptShown = true
        try? await Task.sleep(for: .milliseconds(700))
        let alert = NSAlert()
        alert.messageText = "Allow NetMeter to launch at login"
        alert.informativeText = "macOS needs your approval before NetMeter can start automatically. Turn on NetMeter in System Settings → General → Login Items."
        alert.addButton(withTitle: "Open Login Items")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func quit() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        sample = .zero
        preferences.save(totals: cumulative)
        let previousSave = usageSaveTask
        let snapshot = ledger
        let store = usageStore
        Task { [weak self] in
            await previousSave?.value
            do {
                try await store.save(snapshot)
                NSApp.terminate(nil)
            } catch {
                self?.storageErrorMessage = "Could not save usage history: \(error.localizedDescription)"
                let alert = NSAlert()
                alert.messageText = "Usage history could not be saved"
                alert.informativeText = "\(error.localizedDescription)\n\nYou can keep NetMeter open and try again after fixing the storage problem."
                alert.addButton(withTitle: "Keep Running")
                alert.addButton(withTitle: "Quit Without Saving")
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertSecondButtonReturn {
                    NSApp.terminate(nil)
                } else {
                    self?.startMonitoring()
                }
            }
        }
    }

    private func saveUsage() {
        preferences.save(totals: cumulative)
        let snapshot = ledger
        let previousSave = usageSaveTask
        let store = usageStore
        usageSaveTask = Task { [weak self] in
            await previousSave?.value
            do {
                try await store.save(snapshot)
                self?.storageErrorMessage = nil
            } catch {
                self?.storageErrorMessage = "Could not save usage history: \(error.localizedDescription)"
            }
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
