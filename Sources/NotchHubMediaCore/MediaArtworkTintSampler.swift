import CoreGraphics
import Foundation
import ImageIO

/// Decodes artwork `Data` and samples one fast average color from it, for
/// `MediaArtworkTintCalculator` to clamp into a panel-background tint. Uses
/// only `CoreGraphics`/`ImageIO` (no `AppKit`/`SwiftUI`), so it is real,
/// behaviorally unit-testable logic rather than the source-scanning-only
/// coverage every `NotchHubApp` SwiftUI/AppKit file is limited to — see
/// docs/superpowers/specs/2026-08-24-album-art-color-tinting-design.md.
public enum MediaArtworkTintSampler {
    /// Decodes `artworkData` and returns one clamped legible tint sampled
    /// from it, or `nil` when there is no artwork or it fails to decode —
    /// callers should fall back to `MediaArtworkTintCalculator.fallback` in
    /// that case, exactly reproducing today's flat black panel background.
    public static func sample(artworkData: Data?) -> MediaArtworkTintCalculator.Tint? {
        guard let artworkData, !artworkData.isEmpty else {
            return nil
        }
        guard let (red, green, blue) = averageColor(of: artworkData) else {
            return nil
        }
        let (hue, saturation, brightness) = rgbToHSB(red: red, green: green, blue: blue)
        return MediaArtworkTintCalculator.tint(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// Draws the decoded image into a single 1x1-pixel RGBA context and
    /// reads that one pixel back. Letting Core Graphics' own image
    /// interpolation perform the downsample is the standard fast
    /// average-color technique: its cost is dominated by the initial decode
    /// rather than by source image dimensions, and it needs no manual
    /// per-pixel walk over the source image.
    private static func averageColor(of artworkData: Data) -> (red: Double, green: Double, blue: Double)? {
        guard let source = CGImageSourceCreateWithData(artworkData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixel: [UInt8] = [0, 0, 0, 0]
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let context = CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        guard pixel[3] > 0 else {
            // Fully transparent artwork carries no meaningful color.
            return nil
        }

        // Un-premultiply: the context stores color channels multiplied by
        // alpha, so recover the true channel values before normalizing.
        let alpha = Double(pixel[3]) / 255
        let red = (Double(pixel[0]) / 255) / alpha
        let green = (Double(pixel[1]) / 255) / alpha
        let blue = (Double(pixel[2]) / 255) / alpha
        return (min(red, 1), min(green, 1), min(blue, 1))
    }

    /// Standard piecewise-max/min RGB->HSB conversion. Pure, deterministic,
    /// and independent of `AppKit`/`NSColor`.
    private static func rgbToHSB(red: Double, green: Double, blue: Double) -> (hue: Double, saturation: Double, brightness: Double) {
        let maxValue = max(red, max(green, blue))
        let minValue = min(red, min(green, blue))
        let delta = maxValue - minValue

        let brightness = maxValue
        let saturation = maxValue > 0 ? delta / maxValue : 0

        guard delta > 0 else {
            return (hue: 0, saturation: saturation, brightness: brightness)
        }

        var hue: Double
        if maxValue == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxValue == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        hue /= 6
        if hue < 0 {
            hue += 1
        }
        return (hue: hue, saturation: saturation, brightness: brightness)
    }
}
