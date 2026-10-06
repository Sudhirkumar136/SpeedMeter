import AppKit
import NetMeterCore

@MainActor
enum FixedMeterImage {
    private static let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private static let height: CGFloat = 19

    static func make(title: String, configuration: DisplayConfiguration) -> NSImage {
        // A fixed image size prevents MenuBarExtra from moving the status item as its text changes.
        let characters = MenuBarFormatter.reservedCharacterCount(configuration: configuration)
        let characterWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
        let width = ceil(CGFloat(characters) * characterWidth + 12)
        let size = NSSize(width: width, height: height)

        let image = NSImage(size: size, flipped: false) { bounds in
            let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
            NSColor.labelColor.withAlphaComponent(0.08).setFill()
            outline.fill()
            NSColor.labelColor.withAlphaComponent(0.16).setStroke()
            outline.lineWidth = 1
            outline.stroke()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            let text = title as NSString
            let textHeight = text.size(withAttributes: attributes).height
            text.draw(
                in: NSRect(x: 6, y: (bounds.height - textHeight) / 2, width: bounds.width - 12, height: textHeight),
                withAttributes: attributes
            )
            return true
        }
        image.isTemplate = false
        return image
    }
}
