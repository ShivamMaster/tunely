import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 1.0, green: 0.35, blue: 0.21, alpha: 1.0),
    NSColor(srgbRed: 1.0, green: 0.62, blue: 0.25, alpha: 1.0)
])
gradient?.draw(in: rect, angle: -48)

NSColor.white.withAlphaComponent(0.09).setFill()
NSBezierPath(ovalIn: NSRect(x: 600, y: 560, width: 700, height: 700)).fill()

NSColor.black.withAlphaComponent(0.12).setFill()
NSBezierPath(ovalIn: NSRect(x: -240, y: -260, width: 780, height: 780)).fill()

let heights: [CGFloat] = [260, 500, 380]
let barWidth: CGFloat = 118
let gap: CGFloat = 84
let total = barWidth * 3 + gap * 2
var x = (size - total) / 2
for (index, height) in heights.enumerated() {
    let barRect = NSRect(x: x, y: (size - height) / 2, width: barWidth, height: height)
    NSColor.white.withAlphaComponent(index == 1 ? 1.0 : 0.88).setFill()
    NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
    x += barWidth + gap
}

NSColor.white.withAlphaComponent(0.92).setFill()
NSBezierPath(ovalIn: NSRect(x: 764, y: 748, width: 108, height: 108)).fill()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fatalError("Could not render app icon")
}

let output = URL(fileURLWithPath: "Tunely/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try png.write(to: output)
print("Wrote \(output.path)")
