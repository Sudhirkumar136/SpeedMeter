import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let background = NSBezierPath(roundedRect: NSRect(x: 48, y: 48, width: 928, height: 928), xRadius: 210, yRadius: 210)
let gradient = NSGradient(starting: NSColor(red: 0.05, green: 0.38, blue: 0.88, alpha: 1), ending: NSColor(red: 0.03, green: 0.77, blue: 0.74, alpha: 1))!
gradient.draw(in: background, angle: -35)

NSColor.white.withAlphaComponent(0.16).setStroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 174, y: 174, width: 676, height: 676))
ring.lineWidth = 18
ring.stroke()

func arrow(from start: NSPoint, to end: NSPoint, headLeft: NSPoint, headRight: NSPoint) {
    let shaft = NSBezierPath()
    shaft.move(to: start)
    shaft.line(to: end)
    shaft.lineCapStyle = .round
    shaft.lineJoinStyle = .round
    shaft.lineWidth = 86
    NSColor.white.setStroke()
    shaft.stroke()

    let head = NSBezierPath()
    head.move(to: headLeft)
    head.line(to: end)
    head.line(to: headRight)
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.lineWidth = 86
    head.stroke()
}

arrow(from: NSPoint(x: 350, y: 716), to: NSPoint(x: 350, y: 324), headLeft: NSPoint(x: 220, y: 454), headRight: NSPoint(x: 480, y: 454))
arrow(from: NSPoint(x: 674, y: 308), to: NSPoint(x: 674, y: 700), headLeft: NSPoint(x: 544, y: 570), headRight: NSPoint(x: 804, y: 570))

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render icon") }
try png.write(to: output)
