import SwiftUI

@main
struct NetMeterApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(nsImage: FixedMeterImage.make(title: model.compactMenuTitle, configuration: model.configuration))
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
