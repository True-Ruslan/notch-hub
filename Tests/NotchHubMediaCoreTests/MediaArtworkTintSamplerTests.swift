import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import NotchHubMediaCore

struct MediaArtworkTintSamplerTests {
    @Test
    func sampleReturnsNilForNilArtwork() {
        #expect(MediaArtworkTintSampler.sample(artworkData: nil) == nil)
    }

    @Test
    func sampleReturnsNilForEmptyArtwork() {
        #expect(MediaArtworkTintSampler.sample(artworkData: Data()) == nil)
    }

    @Test
    func sampleReturnsNilForUndecodableArtwork() {
        #expect(MediaArtworkTintSampler.sample(artworkData: Data([0x00, 0x01, 0x02, 0x03])) == nil)
    }

    @Test
    func sampleReturnsNilForFullyTransparentArtwork() {
        let transparent = Self.solidColorPNG(red: 1, green: 0, blue: 0, alpha: 0)
        #expect(MediaArtworkTintSampler.sample(artworkData: transparent) == nil)
    }

    @Test
    func sampleOfSolidRedArtworkYieldsRedHue() throws {
        let red = Self.solidColorPNG(red: 1, green: 0, blue: 0)
        let tint = try #require(MediaArtworkTintSampler.sample(artworkData: red))
        // Pure red is hue 0/1; allow a small tolerance for the wraparound
        // point and for minor color-management drift through PNG encoding.
        #expect(tint.hue < 0.05 || tint.hue > 0.95)
    }

    @Test
    func sampleOfSolidGreenArtworkYieldsGreenHue() throws {
        let green = Self.solidColorPNG(red: 0, green: 1, blue: 0)
        let tint = try #require(MediaArtworkTintSampler.sample(artworkData: green))
        // Pure green is hue 1/3.
        #expect(abs(tint.hue - (1.0 / 3.0)) < 0.05)
    }

    @Test
    func sampleOfSolidBlueArtworkYieldsBlueHue() throws {
        let blue = Self.solidColorPNG(red: 0, green: 0, blue: 1)
        let tint = try #require(MediaArtworkTintSampler.sample(artworkData: blue))
        // Pure blue is hue 2/3.
        #expect(abs(tint.hue - (2.0 / 3.0)) < 0.1)
    }

    @Test
    func sampleClampsResultingSaturationAndBrightness() throws {
        let vividYellow = Self.solidColorPNG(red: 1, green: 1, blue: 0)
        let tint = try #require(MediaArtworkTintSampler.sample(artworkData: vividYellow))
        #expect(tint.saturation <= MediaArtworkTintCalculator.maxSaturation)
        #expect(tint.brightness <= MediaArtworkTintCalculator.maxBrightness)
    }

    @Test
    func sampleOfSolidBlackArtworkYieldsMinimumBrightnessNotZero() throws {
        let black = Self.solidColorPNG(red: 0, green: 0, blue: 0)
        let tint = try #require(MediaArtworkTintSampler.sample(artworkData: black))
        #expect(tint.brightness == MediaArtworkTintCalculator.minBrightness)
        #expect(tint.saturation == 0)
    }

    /// Synthesizes a tiny solid-color PNG entirely in memory, so sampler
    /// tests are deterministic and need no real album artwork fixture.
    private static func solidColorPNG(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1,
        width: Int = 8,
        height: Int = 8
    ) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: alpha))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!

        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}
