import Testing
@testable import NotchHubCore

struct NotchVisualLayoutPolicyTests {
    @Test
    func hardwareNotchCompactSurfaceDoesNotPaintOverPhysicalCornerPixels() {
        #expect(
            NotchVisualLayoutPolicy.compactBackgroundOpacity(
                hasHardwareNotch: true
            ) == 0
        )
    }

    @Test
    func fallbackCompactSurfaceRemainsOpaqueWithoutHardwareNotch() {
        #expect(
            NotchVisualLayoutPolicy.compactBackgroundOpacity(
                hasHardwareNotch: false
            ) == 1
        )
    }

    @Test
    func expandedHardwareNotchContentStartsBelowOccludedArea() {
        let inset = NotchVisualLayoutPolicy.expandedContentTopInset(
            hasHardwareNotch: true,
            compactHeight: 32
        )

        #expect(inset > 32)
        #expect(inset == 44)
    }

    @Test
    func expandedFallbackContentKeepsStandardInset() {
        #expect(
            NotchVisualLayoutPolicy.expandedContentTopInset(
                hasHardwareNotch: false,
                compactHeight: 32
            ) == 20
        )
    }
}
