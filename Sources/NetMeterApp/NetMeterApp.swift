import SwiftUI

@main
struct NetMeterApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Text(model.menuTitle)
                .monospacedDigit()
                .accessibilityLabel("NetMeter network usage: \(model.menuTitle)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }

        Window("Usage Statistics", id: "usage-statistics") {
            UsageStatisticsView(model: model)
        }
        .defaultSize(width: 720, height: 620)
    }
}
