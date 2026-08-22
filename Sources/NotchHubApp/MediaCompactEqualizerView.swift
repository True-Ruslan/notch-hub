import SwiftUI

/// A small animated equalizer for Compact's right wing, replacing a static
/// play/pause glyph. Purely a projection of the already-published
/// `playbackState` — it observes no audio signal and starts no new media
/// transport. Animation is driven by SwiftUI's declarative, Core-Animation-
/// backed `repeatForever`, not by any timer primitive; see
/// docs/superpowers/specs/2026-08-22-compact-live-equalizer-design.md.
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

private struct EqualizerBar: View {
    let duration: Double
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let isPlaying: Bool

    @State private var isGrown = false

    var body: some View {
        Capsule()
            .fill(.white.opacity(isPlaying ? 0.9 : 0.5))
            .frame(width: 3, height: isGrown ? maxHeight : minHeight)
            .animation(
                isPlaying
                    ? .easeInOut(duration: duration).repeatForever(autoreverses: true)
                    : .easeInOut(duration: 0.2),
                value: isGrown
            )
            .onAppear {
                isGrown = isPlaying
            }
            .onChange(of: isPlaying) { _, playing in
                isGrown = playing
            }
    }
}
