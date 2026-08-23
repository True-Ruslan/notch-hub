import Foundation

/// Pure overflow/timing math for `MediaMarqueeText`, kept free of SwiftUI so
/// it can be unit-tested deterministically. See
/// docs/superpowers/specs/2026-08-22-media-marquee-text-design.md.
public enum MediaMarqueeCalculator {
    /// Horizontal scroll speed for the looping "conveyor" animation.
    public static let pointsPerSecond: Double = 30

    /// Blank space between the end of one copy of the content and the start
    /// of the next, so the loop reads as a continuous conveyor rather than
    /// an abrupt jump.
    public static let gapPoints: CGFloat = 24

    /// Floor on the animation cycle duration, so content that overflows by
    /// only a fraction of a point never produces a near-instant, jarring
    /// loop.
    public static let minCycleDuration: Double = 1.0

    /// Whether `contentWidth` is wide enough to be clipped by
    /// `availableWidth` and therefore needs to scroll.
    public static func needsScrolling(contentWidth: CGFloat, availableWidth: CGFloat) -> Bool {
        contentWidth > availableWidth
    }

    /// Duration of one full scroll cycle: one content width plus the gap,
    /// travelled at `pointsPerSecond`, clamped to `minCycleDuration`.
    ///
    /// Only meaningful when `needsScrolling` is `true` for the same
    /// `contentWidth`/`availableWidth` pair.
    public static func cycleDuration(contentWidth: CGFloat, availableWidth: CGFloat) -> Double {
        let distance = Double(contentWidth) + Double(gapPoints)
        return max(minCycleDuration, distance / pointsPerSecond)
    }
}
