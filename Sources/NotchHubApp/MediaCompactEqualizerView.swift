import SwiftUI

/// A small animated equalizer for Compact's right wing, replacing a static
/// play/pause glyph. Purely a projection of the already-published
/// `playbackState` — it observes no audio signal and starts no new media
/// transport. Animation is driven by SwiftUI's `PhaseAnimator`, a
/// declarative, Core-Animation-backed looping mechanism — not by any timer
/// primitive; see
/// docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md.
///
/// `PhaseAnimator` (not the older `.repeatForever` modifier) is used
/// specifically because a repeating implicit animation can be silently
/// frozen when an unrelated ancestor view commits its own explicit
/// `withAnimation` transaction (observed here: the horizontal swipe gesture
/// used for next/previous freezing the bars until the panel was
/// expanded and collapsed again, which force-recreated the view).
/// `PhaseAnimator` owns its own animation timeline and is unaffected by
/// ancestor transactions.
struct MediaCompactEqualizerView: View {
    let isPlaying: Bool

    private static let barDurations: [Double] = [0.46, 0.62, 0.52]
    private static let barMinHeights: [CGFloat] = [4, 6, 5]
    private static let barMaxHeights: [CGFloat] = [12, 16, 14]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<Self.barDurations.count, id: \.self) { index in
                EqualizerBar(
                    duration: Self.barDurations[index],
                    minHeight: Self.barMinHeights[index],
                    maxHeight: Self.barMaxHeights[index],
                    isPlaying: isPlaying
                )
            }
        }
        .frame(width: 36, height: 32)
    }
}

private enum EqualizerBarPhase: CaseIterable, Equatable {
    case low
    case high
}

private struct EqualizerBar: View {
    let duration: Double
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let isPlaying: Bool

    var body: some View {
        Group {
            if isPlaying {
                PhaseAnimator(EqualizerBarPhase.allCases) { phase in
                    Capsule()
                        .fill(.white.opacity(0.9))
                        .frame(width: 3, height: phase == .high ? maxHeight : minHeight)
                } animation: { _ in
                    .easeInOut(duration: duration)
                }
            } else {
                Capsule()
                    .fill(.white.opacity(0.5))
                    .frame(width: 3, height: minHeight)
            }
        }
        .frame(width: 3, height: maxHeight, alignment: .center)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}
