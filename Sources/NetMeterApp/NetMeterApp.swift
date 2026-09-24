import AppKit
import NetMeterCore
import SwiftUI

@main
struct NetMeterApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            if model.isMonitoring && !model.menuItems.isEmpty {
                HStack(spacing: 6) {
                    ForEach(model.menuItems) { item in
                        Text(item.text)
                            .frame(width: reservedWidth(for: item.metric), alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .font(.system(size: NSFont.systemFontSize, design: .monospaced))
                .accessibilityLabel("NetMeter network usage: \(model.menuTitle)")
            } else {
                Text(model.menuTitle)
            }
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

    private func reservedWidth(for metric: Metric) -> CGFloat {
        let config = model.configuration.normalized
        let symbolLength: Int
        let unitLength: Int
        switch metric {
        case .downloadSpeed:
            symbolLength = config.symbolStyle.download.count + 1
            unitLength = config.showUnits ? 5 : 0
        case .uploadSpeed:
            symbolLength = config.symbolStyle.upload.count + 1
            unitLength = config.showUnits ? 5 : 0
        case .totalDownloaded:
            symbolLength = config.symbolStyle.download.count + 2
            unitLength = config.showUnits ? 3 : 0
        case .totalUploaded:
            symbolLength = config.symbolStyle.upload.count + 2
            unitLength = config.showUnits ? 3 : 0
        case .totalUsed:
            symbolLength = 2
            unitLength = config.showUnits ? 3 : 0
        }
        let decimalLength = config.decimalPrecision == 0 ? 0 : config.decimalPrecision + 1
        let characters = symbolLength + 4 + decimalLength + unitLength
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let characterWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
        return ceil(CGFloat(characters) * characterWidth + 6)
    }
}
