import Testing
@testable import NotchHubMediaCore

struct MediaGestureInputNormalizerTests {
    @Test
    func physicalLeftDownIsStableAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 18,
            scrollingDeltaY: -24,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: -18,
            scrollingDeltaY: 24,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: -18, y: 24))
        #expect(inverted == regular)
    }

    @Test
    func physicalRightUpIsStableAcrossSystemScrollDirectionPreference() {
        let regular = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: -18,
            scrollingDeltaY: 24,
            isDirectionInvertedFromDevice: false
        )
        let inverted = MediaGestureInputNormalizer.semanticDeltas(
            scrollingDeltaX: 18,
            scrollingDeltaY: -24,
            isDirectionInvertedFromDevice: true
        )

        #expect(regular == MediaGestureInputDeltas(x: 18, y: -24))
        #expect(inverted == regular)
    }
}
