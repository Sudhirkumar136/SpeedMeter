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
            Text(model.compactMenuTitle)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: reservedWidth, alignment: .leading)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.primary.opacity(0.15)))
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

    private var reservedWidth: CGFloat {
        let characters = MenuBarFormatter.reservedCharacterCount(configuration: model.configuration)
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let characterWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
        return ceil(CGFloat(characters) * characterWidth + 4)
    }
}
