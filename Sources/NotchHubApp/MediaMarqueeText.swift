import NotchHubMediaCore
import SwiftUI

/// A single line of text that renders exactly as static, tail-truncated
/// `Text` when it fits its available width, and only scrolls when it
/// genuinely overflows. See
/// docs/superpowers/specs/2026-08-22-media-marquee-text-design.md.
///
/// Overflow/timing math lives in the pure, unit-tested
/// `MediaMarqueeCalculator`. The scroll animation itself is driven by
/// SwiftUI's `PhaseAnimator`, the same self-contained, ancestor-transaction-immune
/// mechanism `MediaCompactEqualizerView` uses, rather than a repeating-timer
/// or periodic-timeline-driven primitive.
struct MediaMarqueeText: View {
    let text: String
    let font: Font
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentWidth: CGFloat = 0
    @State private var availableWidth: CGFloat = 0

    private var shouldScroll: Bool {
        !reduceMotion
            && MediaMarqueeCalculator.needsScrolling(
                contentWidth: contentWidth,
                availableWidth: availableWidth
            )
    }

    var body: some View {
        Group {
            if shouldScroll {
                scrollingConveyor
            } else {
                staticText
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) { _, newValue in
                        availableWidth = newValue
                    }
            }
        )
        .background(
            Text(text)
                .font(font)
                .fixedSize()
                .hidden()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.size.width, initial: true) { _, newValue in
                                contentWidth = newValue
                            }
                    }
                )
        )
    }

    private var staticText: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var scrollingConveyor: some View {
        let travel = contentWidth + MediaMarqueeCalculator.gapPoints
        let duration = MediaMarqueeCalculator.cycleDuration(
            contentWidth: contentWidth,
            availableWidth: availableWidth
        )

        return PhaseAnimator(MediaMarqueeScrollPhase.allCases) { phase in
            HStack(spacing: MediaMarqueeCalculator.gapPoints) {
                marqueeSegment
                marqueeSegment
            }
            .fixedSize()
            .offset(x: phase == .end ? -travel : 0)
        } animation: { _ in
            .linear(duration: duration)
        }
        .frame(width: availableWidth, alignment: .leading)
        .clipped()
    }

    private var marqueeSegment: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
    }
}

private enum MediaMarqueeScrollPhase: CaseIterable, Equatable {
    case start
    case end
}
