import Testing

@testable import NotchHubMediaCore

struct MediaArtworkTintCalculatorTests {
    @Test
    func tintPassesThroughValueWithinAllowedRanges() {
        let tint = MediaArtworkTintCalculator.tint(hue: 0.5, saturation: 0.2, brightness: 0.2)
        #expect(tint.hue == 0.5)
        #expect(tint.saturation == 0.2)
        #expect(tint.brightness == 0.2)
    }

    @Test
    func tintClampsSaturationToMaximum() {
        let tint = MediaArtworkTintCalculator.tint(hue: 0.1, saturation: 1.0, brightness: 0.2)
        #expect(tint.saturation == MediaArtworkTintCalculator.maxSaturation)
    }

    @Test
    func tintClampsBrightnessToMaximum() {
        let tint = MediaArtworkTintCalculator.tint(hue: 0.1, saturation: 0.2, brightness: 1.0)
        #expect(tint.brightness == MediaArtworkTintCalculator.maxBrightness)
    }

    @Test
    func tintClampsBrightnessToMinimumForNearBlackInput() {
        let tint = MediaArtworkTintCalculator.tint(hue: 0, saturation: 0, brightness: 0)
        #expect(tint.brightness == MediaArtworkTintCalculator.minBrightness)
    }

    @Test
    func tintClampsOutOfRangeHueIntoUnitInterval() {
        let tooHigh = MediaArtworkTintCalculator.tint(hue: 4.0, saturation: 0.1, brightness: 0.1)
        #expect(tooHigh.hue == 1)

        let negative = MediaArtworkTintCalculator.tint(hue: -2.0, saturation: 0.1, brightness: 0.1)
        #expect(negative.hue == 0)
    }

    @Test
    func tintFallsBackToSafeDefaultsForNonFiniteInput() {
        let tint = MediaArtworkTintCalculator.tint(hue: .nan, saturation: .infinity, brightness: -.infinity)
        #expect(tint.hue == 0)
        #expect(tint.saturation == 0)
        #expect(tint.brightness == MediaArtworkTintCalculator.minBrightness)
    }

    @Test
    func tintClampsNegativeBrightnessUpToMinimum() {
        let tint = MediaArtworkTintCalculator.tint(hue: 0.3, saturation: 0.1, brightness: -5)
        #expect(tint.brightness == MediaArtworkTintCalculator.minBrightness)
    }

    @Test
    func fallbackIsExactlyFlatBlack() {
        let fallback = MediaArtworkTintCalculator.fallback
        #expect(fallback.hue == 0)
        #expect(fallback.saturation == 0)
        #expect(fallback.brightness == 0)
    }
}
