// Startbild (2732 × 2732): dunkler Grund wie die App (#232323), in der Mitte das runde HLB-Symbol.
// Aufruf: xcrun swift homelab/startbild_zeichnen.swift <symbol-rund.png> <ziel.png>
import AppKit
let n = 2732, s = 640
let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(red: 0x23 / 255.0, green: 0x23 / 255.0, blue: 0x23 / 255.0, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
let symbol = NSImage(contentsOfFile: CommandLine.arguments[1])!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
ctx.draw(symbol, in: CGRect(x: (n - s) / 2, y: (n - s) / 2, width: s, height: s))
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
  .write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
