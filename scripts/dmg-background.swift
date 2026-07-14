// dmg-background.swift — draw the VistaClock installer DMG background.
//
// Renders the window backdrop: title, a drag arrow from the app icon toward the
// Applications folder, and the one-time first-launch (Gatekeeper) steps. The two
// icons themselves are placed by Finder; this only draws everything around them.
//
// Usage:  swift dmg-background.swift <out.png> <scale>   (scale 1 or 2)

import AppKit
import Foundation

let W: CGFloat = 680
let H: CGFloat = 520

let args = CommandLine.arguments
guard args.count >= 3, let scale = Int(args[2]) else {
    FileHandle.standardError.write(Data("usage: dmg-background.swift <out.png> <scale>\n".utf8))
    exit(1)
}
let outPath = args[1]

let pw = Int(W) * scale
let ph = Int(H) * scale
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { exit(2) }

let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
// Draw in points; scale up to the (possibly 2x) pixel buffer.
let xform = NSAffineTransform(); xform.scale(by: CGFloat(scale)); xform.concat()

// Layout is expressed in Finder's top-left / y-down coordinates; convert to the
// bottom-left / y-up drawing space here so text renders upright (no context flip).
func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: H - y - h, width: w, height: h)
}
func P(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: H - y) }

func text(_ s: String, _ rect: NSRect, _ size: CGFloat, _ weight: NSFont.Weight,
          _ color: NSColor, _ align: NSTextAlignment, lineSpacing: CGFloat = 0) {
    let para = NSMutableParagraphStyle()
    para.alignment = align
    para.lineSpacing = lineSpacing
    (s as NSString).draw(in: rect, withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: para,
    ])
}

// Backdrop: soft vertical gradient.
NSGradient(starting: NSColor(calibratedWhite: 1.0, alpha: 1),
           ending: NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.96, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Title + subtitle.
text("VistaClock", R(0, 32, W, 40), 30, .bold, NSColor(white: 0.13, alpha: 1), .center)
text("Menu-bar clock, calendar & world clocks", R(0, 74, W, 20), 13, .regular,
     NSColor(white: 0.45, alpha: 1), .center)

// Drag arrow between the icon slots (app icon ~x=180, Applications ~x=500, y=215).
let accent = NSColor(calibratedRed: 0.28, green: 0.53, blue: 0.95, alpha: 1)
accent.setStroke(); accent.setFill()
let ay: CGFloat = 215
let tip = P(430, ay)
let shaft = NSBezierPath()
shaft.lineWidth = 9
shaft.lineCapStyle = .round
shaft.move(to: P(252, ay))
shaft.line(to: NSPoint(x: tip.x - 12, y: tip.y))
shaft.stroke()
let head = NSBezierPath()
head.move(to: NSPoint(x: tip.x + 10, y: tip.y))
head.line(to: NSPoint(x: tip.x - 18, y: tip.y + 18))
head.line(to: NSPoint(x: tip.x - 18, y: tip.y - 18))
head.close(); head.fill()

// Caption under the icons.
text("Drag VistaClock onto the Applications folder", R(0, 300, W, 22), 15, .semibold,
     NSColor(white: 0.22, alpha: 1), .center)

// First-launch instruction panel.
let panel = R(40, 344, W - 80, 150)
let panelPath = NSBezierPath(roundedRect: panel, xRadius: 12, yRadius: 12)
NSColor(white: 1.0, alpha: 0.7).setFill(); panelPath.fill()
NSColor(white: 0.82, alpha: 1).setStroke(); panelPath.lineWidth = 1; panelPath.stroke()

text("First launch — one time only", R(64, 358, W - 128, 20), 13, .semibold,
     NSColor(white: 0.18, alpha: 1), .left)
let steps = """
This app isn't notarized, so macOS blocks the first open.
1.   Double-click VistaClock, then click Done.
2.   Open System Settings ▸ Privacy & Security, scroll down, click “Open Anyway”.
3.   Open VistaClock again — it won't ask again.
"""
text(steps, R(64, 382, W - 128, 104), 12.5, .regular, NSColor(white: 0.3, alpha: 1),
     .left, lineSpacing: 4)

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { exit(3) }
try! png.write(to: URL(fileURLWithPath: outPath))
