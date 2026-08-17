import Testing
@testable import NotchHubMediaCore

struct MediaGestureInputNormalizerTests {
    @Test
    func physicalRightXIsPositiveAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: -18,
            scrollingDeltaY: 0,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 18,
            scrollingDeltaY: 0,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: 18, y: 0))
        #expect(inverted == regular)
    }

    @Test
    func physicalLeftXIsNegativeAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 18,
            scrollingDeltaY: 0,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: -18,
            scrollingDeltaY: 0,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: -18, y: 0))
        #expect(inverted == regular)
    }

    @Test
    func physicalDownYRemainsPositiveAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 0,
            scrollingDeltaY: -24,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 0,
            scrollingDeltaY: 24,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: 0, y: 24))
        #expect(inverted == regular)
    }

    @Test
    func physicalUpYRemainsNegativeAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 0,
            scrollingDeltaY: 24,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 0,
            scrollingDeltaY: -24,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: 0, y: -24))
        #expect(inverted == regular)
    }
}
