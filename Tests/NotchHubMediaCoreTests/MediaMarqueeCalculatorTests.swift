import Testing

@testable import NotchHubMediaCore

struct MediaMarqueeCalculatorTests {
    @Test
    func needsScrollingReturnsFalseWhenContentFitsExactly() {
        #expect(
            !MediaMarqueeCalculator.needsScrolling(contentWidth: 100, availableWidth: 100)
        )
    }

    @Test
    func needsScrollingReturnsFalseWhenContentIsNarrower() {
        #expect(
            !MediaMarqueeCalculator.needsScrolling(contentWidth: 80, availableWidth: 100)
        )
    }

    @Test
    func needsScrollingReturnsTrueWhenContentOverflows() {
        #expect(
            MediaMarqueeCalculator.needsScrolling(contentWidth: 240, availableWidth: 100)
        )
    }

    @Test
    func needsScrollingReturnsFalseForEmptyContent() {
        #expect(
            !MediaMarqueeCalculator.needsScrolling(contentWidth: 0, availableWidth: 100)
        )
    }

    @Test
    func cycleDurationScalesWithOverflowDistanceAtFixedSpeed() {
        let smallOverflow = MediaMarqueeCalculator.cycleDuration(
            contentWidth: 130,
            availableWidth: 100
        )
        let expectedSmall =
            (130 + MediaMarqueeCalculator.gapPoints) / MediaMarqueeCalculator.pointsPerSecond
        #expect(smallOverflow == expectedSmall)

        let largeOverflow = MediaMarqueeCalculator.cycleDuration(
            contentWidth: 400,
            availableWidth: 100
        )
        let expectedLarge =
            (400 + MediaMarqueeCalculator.gapPoints) / MediaMarqueeCalculator.pointsPerSecond
        #expect(largeOverflow == expectedLarge)
        #expect(largeOverflow > smallOverflow)
    }

    @Test
    func cycleDurationIsClampedToMinimumForPathologicalNearZeroOverflow() {
        // A tiny content width still overflows a smaller available width,
        // but the unclamped distance/speed math would fall below one
        // second — the clamp must bring it back up to exactly the floor.
        let duration = MediaMarqueeCalculator.cycleDuration(
            contentWidth: 2,
            availableWidth: 1
        )
        let unclamped =
            (2 + Double(MediaMarqueeCalculator.gapPoints)) / MediaMarqueeCalculator.pointsPerSecond
        #expect(unclamped < MediaMarqueeCalculator.minCycleDuration)
        #expect(duration == MediaMarqueeCalculator.minCycleDuration)
    }

    @Test
    func pointsPerSecondAndGapPointsAreStableConstants() {
        #expect(MediaMarqueeCalculator.pointsPerSecond == 30)
        #expect(MediaMarqueeCalculator.gapPoints == 24)
        #expect(MediaMarqueeCalculator.minCycleDuration == 1.0)
    }
}
