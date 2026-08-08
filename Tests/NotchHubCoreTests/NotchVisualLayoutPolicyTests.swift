import Testing
@testable import NotchHubCore

struct NotchVisualLayoutPolicyTests {
    @Test
    func hardwareNotchCompactSurfaceDoesNotPaintOverPhysicalCornerPixels() {
        let metrics = NotchVisualLayoutPolicy.metrics(
            hasHardwareNotch: true,
            compactHeight: 32
        )

        #expect(metrics.compactBackgroundOpacity == 0)
    }

    @Test
    func fallbackCompactSurfaceRemainsOpaqueWithoutHardwareNotch() {
        let metrics = NotchVisualLayoutPolicy.metrics(
            hasHardwareNotch: false,
            compactHeight: 32
        )

        #expect(metrics.compactBackgroundOpacity == 1)
    }

    @Test
    func expandedHardwareNotchContentStartsBelowOccludedArea() {
        let metrics = NotchVisualLayoutPolicy.metrics(
            hasHardwareNotch: true,
            compactHeight: 32
        )

        #expect(metrics.expandedContentTopInset > 32)
        #expect(metrics.expandedContentTopInset == 44)
    }

    @Test
    func expandedFallbackContentKeepsStandardInset() {
        let metrics = NotchVisualLayoutPolicy.metrics(
            hasHardwareNotch: false,
            compactHeight: 32
        )

        #expect(metrics.expandedContentTopInset == 20)
    }
}
