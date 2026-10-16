// App-Symbol HomeLabBooks (1024 × 1024, deckend): Monogramm «HLB» in weissen, runden Strichen auf einem
// Farbverlauf Petrol -> Grün, im Stil des HomeLabMusic-Symbols («HLM» auf Rot).
// Aufruf: xcrun swift homelab/icon_zeichnen.swift <ziel.png> [--transparent | --rund]
//   ohne Option: deckend ohne Alphakanal (App-Symbol, App Store verlangt das)
//   --transparent: nur das Zeichen (Startbild)   --rund: mit runden Ecken (Logo der Anmeldeseite)
import AppKit
import CoreGraphics

let n = 1024
let transparent = CommandLine.arguments.contains("--transparent")
let rund = CommandLine.arguments.contains("--rund")
let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: (transparent || rund ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue)!
ctx.translateBy(x: 0, y: CGFloat(n)); ctx.scaleBy(x: 1, y: -1)          // y nach unten

if rund {
  ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: n, height: n), cornerWidth: 225, cornerHeight: 225, transform: nil))
  ctx.clip()
}
if !transparent {
  // Verlauf oben links hell -> unten rechts dunkel, wie beim HLM-Symbol
  let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
    CGColor(red: 0.16, green: 0.78, blue: 0.70, alpha: 1),
    CGColor(red: 0.04, green: 0.58, blue: 0.52, alpha: 1),
    CGColor(red: 0.02, green: 0.40, blue: 0.48, alpha: 1)] as CFArray, locations: [0, 0.5, 1])!
  ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: CGFloat(n), y: CGFloat(n)), options: [])
  // leichter Glanz oben links
  let glanz = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.16), CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
    locations: [0, 1])!
  ctx.drawRadialGradient(glanz, startCenter: CGPoint(x: 120, y: 80), startRadius: 0,
                         endCenter: CGPoint(x: 120, y: 80), endRadius: 700, options: [])
}

ctx.setStrokeColor(CGColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1))
ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.setLineWidth(78)
if !transparent { ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: CGColor(gray: 0, alpha: 0.18)) }
ctx.beginTransparencyLayer(auxiliaryInfo: nil)          // ein Schatten für das ganze Zeichen, nicht pro Strich

func linie(_ pts: [(CGFloat, CGFloat)]) {
  ctx.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
  for p in pts.dropFirst() { ctx.addLine(to: CGPoint(x: p.0, y: p.1)) }
  ctx.strokePath()
}

// H (linker Stamm, Querbalken) und der hohe Stamm, der zugleich das L ist
linie([(152, 352), (152, 650)])
linie([(152, 490), (410, 490)])
linie([(410, 255), (410, 760), (650, 760)])

// B: Stamm, oberer und unterer Bogen (unten etwas breiter)
let x0: CGFloat = 535, oben: CGFloat = 290, mitte: CGFloat = 465, unten: CGFloat = 640
let r: CGFloat = (mitte - oben) / 2
ctx.move(to: CGPoint(x: x0, y: oben))
ctx.addLine(to: CGPoint(x: 680, y: oben))
ctx.addArc(center: CGPoint(x: 680, y: oben + r), radius: r, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
ctx.addLine(to: CGPoint(x: x0, y: mitte))
ctx.move(to: CGPoint(x: x0, y: mitte))
ctx.addLine(to: CGPoint(x: 725, y: mitte))
ctx.addArc(center: CGPoint(x: 725, y: mitte + r), radius: r, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
ctx.addLine(to: CGPoint(x: x0, y: unten))
ctx.addLine(to: CGPoint(x: x0, y: oben))
ctx.strokePath()

ctx.endTransparencyLayer()

let bild = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: bild)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("geschrieben:", CommandLine.arguments[1])
