import AppKit
import NetMeterCore

@MainActor
enum FixedMeterImage {
    private static let height: CGFloat = 19
    private static let padding: CGFloat = 6

    static func make(title: String, columns: [MenuBarColumn], configuration: DisplayConfiguration) -> NSImage {
        let config = configuration.normalized
        let regular = NSFont.monospacedSystemFont(ofSize: CGFloat(config.menuBarFontSize), weight: .regular)
        let gap = glyphWidth(for: regular)

        let reservedColumns = MenuBarFormatter.columns(
            downloadBytesPerSecond: 0,
            uploadBytesPerSecond: 0,
            totalDownloaded: 0,
            totalUploaded: 0,
            configuration: config
        )
        let segments: [(text: String, font: NSFont, width: CGFloat)]
        if columns.isEmpty {
            let reservedWidth = reservedColumns.reduce(CGFloat(0)) { total, column in
                total + CGFloat(column.characterWidth) * glyphWidth(for: font(for: column.metric, configuration: config))
            } + gap * CGFloat(max(0, reservedColumns.count - 1))
            segments = [(title, regular, max(CGFloat(max(8, title.count)) * glyphWidth(for: regular), reservedWidth))]
        } else {
            segments = columns.map { column in
                let font = font(for: column.metric, configuration: config)
                return (column.text, font, CGFloat(column.characterWidth) * glyphWidth(for: font))
            }
        }

        let width = ceil(segments.reduce(padding * 2, { $0 + $1.width }) + gap * CGFloat(max(0, segments.count - 1)))
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { bounds in
            var x = padding
            for segment in segments {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = columns.isEmpty ? .left : .right
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: segment.font,
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph
                ]
                let text = segment.text as NSString
                let textHeight = text.size(withAttributes: attributes).height
                text.draw(
                    in: NSRect(x: x, y: (bounds.height - textHeight) / 2, width: segment.width, height: textHeight),
                    withAttributes: attributes
                )
                x += segment.width + gap
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    private static func font(for metric: Metric, configuration: DisplayConfiguration) -> NSFont {
        let choice: MenuBarFontWeight = switch metric {
        case .downloadSpeed: configuration.downloadFontWeight
        case .uploadSpeed: configuration.uploadFontWeight
        case .totalDownloaded, .totalUploaded, .totalUsed: .regular
        }
        let weight: NSFont.Weight = switch choice {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
        return NSFont.monospacedSystemFont(ofSize: CGFloat(configuration.menuBarFontSize), weight: weight)
    }

    private static func glyphWidth(for font: NSFont) -> CGFloat {
        ["0", "8", "↓", "↑", "⇣", "⇡", "Σ", "D", "L", "U", ":", "M", "W"]
            .map { ($0 as NSString).size(withAttributes: [.font: font]).width }
            .max() ?? 8
    }
}
