import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Created in 2026 by Kimihiko Mizutani (Kyoto University).

let version = "0.1.1"

struct Arguments {
    var input: URL
    var output: URL?
    var recursive = false
    var outputDirectory: URL?
    var quality: CGFloat = 0.92
    var scale: CGFloat = 1
}

func usage() -> Never {
    print("Usage: quickdraw-jpeg [--quality 0.0..1.0] [--scale N] INPUT [OUTPUT.jpg]")
    print("       quickdraw-jpeg --recursive INPUT-DIRECTORY --output-directory OUTPUT-DIRECTORY [--quality Q] [--scale N]")
    exit(2)
}

func parseArguments() -> Arguments {
    var values = Array(CommandLine.arguments.dropFirst())
    var quality: CGFloat = 0.92
    var scale: CGFloat = 1
    var recursive = false
    var outputDirectory: URL?
    var positional: [String] = []
    while !values.isEmpty {
        let value = values.removeFirst()
        switch value {
        case "--recursive", "-r": recursive = true
        case "--output-directory", "-o":
            guard let path = values.first else { usage() }
            _ = values.removeFirst(); outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        case "--quality", "-q":
            guard let text = values.first, let number = Double(text), (0...1).contains(number) else { usage() }
            _ = values.removeFirst(); quality = CGFloat(number)
        case "--scale":
            guard let text = values.first, let number = Double(text), number > 0, number <= 32 else { usage() }
            _ = values.removeFirst(); scale = CGFloat(number)
        case "--version", "-v":
            print("quickdraw-jpeg \(version)")
            exit(0)
        case "--help", "-h": usage()
        default: positional.append(value)
        }
    }
    guard let input = positional.first else { usage() }
    let source = URL(fileURLWithPath: input)
    guard !recursive || (outputDirectory != nil && positional.count == 1) else { usage() }
    let output = positional.dropFirst().first.map(URL.init(fileURLWithPath:))
        ?? (recursive ? nil : source.deletingPathExtension().appendingPathExtension("jpg"))
    return Arguments(input: source, output: output, recursive: recursive, outputDirectory: outputDirectory, quality: quality, scale: scale)
}

final class BitmapRenderer: QuickdrawCGRenderer {
    let bitmap: CGContext
    init(bitmap: CGContext) { self.bitmap = bitmap; super.init(context: bitmap) }
}

// A classic PICT file starts with a 2-byte size, an 8-byte frame rectangle,
// and then a version opcode. Some files have a 512-byte resource-fork header
// in front of this structure, so check both possible offsets.
func isLikelyPICT(_ data: Data) -> Bool {
    guard data.count >= 12 else { return false }
    let offsets = [0, 512]
    for offset in offsets where data.count >= offset + 12 {
        let version = UInt16(data[offset + 10]) << 8 | UInt16(data[offset + 11])
        if version == 0x0011 || version == 0x1101 {
            return true
        }
    }
    return false
}

func convert(input: URL, output: URL, quality: CGFloat, scale: CGFloat) throws {
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try Data(contentsOf: input)
    let parser = try QDParser(data: data)
    parser.filename = input.path
    let picture = try parser.parse()
    let width = max(1, Int((CGFloat(picture.frame.dimensions.dh.value) * scale).rounded(.up)))
    let height = max(1, Int((CGFloat(picture.frame.dimensions.dv.value) * scale).rounded(.up)))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: width * 4, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw NSError(domain: "QuickDrawJPEG", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create bitmap context"])
    }
    context.setFillColor(CGColor.white); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    // QuickDraw uses a top-left origin, while a bitmap CGContext uses a
    // bottom-left origin. Flip the drawing space so the rendered picture is
    // saved with the same vertical orientation as the original PICT.
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    let renderer = BitmapRenderer(bitmap: context)
    try renderer.execute(picture: picture, zoom: scale)
    guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw NSError(domain: "QuickDrawJPEG", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create JPEG destination"])
    }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "QuickDrawJPEG", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to write JPEG"]) }
    print("\(input.path) -> \(output.path) (\(width)x\(height))")
}

do {
    let args = parseArguments()
    if args.recursive {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: args.input.path, isDirectory: &isDirectory), isDirectory.boolValue,
              let root = args.outputDirectory else { usage() }
        let enumerator = fm.enumerator(at: args.input, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var converted = 0
        while let item = enumerator?.nextObject() as? URL {
            guard (try? item.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
            let ext = item.pathExtension.lowercased()
            let hasPICTExtension = ext == "pict" || ext == "pic"
            let isPICT = hasPICTExtension || (try? isLikelyPICT(Data(contentsOf: item))) == true
            guard isPICT else { continue }
            let relative = item.path.replacingOccurrences(of: args.input.path + "/", with: "")
            let output = root.appendingPathComponent(relative).deletingPathExtension().appendingPathExtension("jpg")
            do { try convert(input: item, output: output, quality: args.quality, scale: args.scale); converted += 1 }
            catch { fputs("quickdraw-jpeg: failed (\(item.path)): \(error)\n", stderr) }
        }
        print("Converted \(converted) file(s).")
    } else {
        guard let output = args.output else { usage() }
        try convert(input: args.input, output: output, quality: args.quality, scale: args.scale)
    }
} catch { fputs("quickdraw-jpeg: \(error)\n", stderr); exit(1) }
