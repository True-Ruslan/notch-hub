import Foundation

/// Pure clamping math that turns a raw sampled artwork color into a subtle,
/// legible panel-background tint, kept free of SwiftUI/AppKit so it can be
/// unit-tested deterministically. See
/// docs/superpowers/specs/2026-08-24-album-art-color-tinting-design.md.
public enum MediaArtworkTintCalculator {
    /// Upper bound on tint saturation, so a vivid album cover never turns
    /// the panel background into a color-picker swatch.
    public static let maxSaturation: Double = 0.55

    /// Upper bound on tint brightness, so a bright album cover never makes
    /// the background compete with the white title/artist/chrome text drawn
    /// over it.
    public static let maxBrightness: Double = 0.34

    /// Lower bound on tint brightness, so a fully black/near-black album
    /// cover still reads as "a dark tint" rather than crushing to literal
    /// zero-brightness black (which would be visually identical to the
    /// pre-tint default and defeats the purpose of this feature).
    public static let minBrightness: Double = 0.05

    /// One legible, clamped panel-background tint.
    public struct Tint: Equatable, Sendable {
        public let hue: Double
        public let saturation: Double
        public let brightness: Double

        public init(hue: Double, saturation: Double, brightness: Double) {
            self.hue = hue
            self.saturation = saturation
            self.brightness = brightness
        }
    }

    /// The tint used when there is no artwork, or when raw sampled color is
    /// unavailable/unusable — must exactly reproduce today's flat black
    /// panel background, so the no-artwork/generic-Peek path renders
    /// identically to before this feature existed.
    public static let fallback = Tint(hue: 0, saturation: 0, brightness: 0)

    /// Clamps a raw sampled artwork color into a subtle, legible panel
    /// background tint. Input is conventionally HSB with each component in
    /// `0...1`, but the function defensively clamps out-of-range and
    /// non-finite input rather than trusting the caller, since the caller
    /// samples from arbitrary, possibly malformed, third-party artwork.
    public static func tint(hue: Double, saturation: Double, brightness: Double) -> Tint {
        Tint(
            hue: safeUnitInterval(hue, default: 0),
            saturation: min(safeUnitInterval(saturation, default: 0), maxSaturation),
            brightness: min(
                max(safeUnitInterval(brightness, default: minBrightness), minBrightness),
                maxBrightness
            )
        )
    }

    private static func safeUnitInterval(_ value: Double, default fallbackValue: Double) -> Double {
        guard value.isFinite else {
            return fallbackValue
        }
        return min(max(value, 0), 1)
    }
}
