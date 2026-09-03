import AppKit
import NotchHubCore
import NotchHubMediaCore
import SwiftUI

@MainActor
struct MediaNotchRootView: View {
    @ObservedObject private var panelModel: NotchPanelModel
    @ObservedObject private var layoutModel: NotchPanelLayoutModel
    @ObservedObject private var mediaModel: ShippingMediaPresentationModel
    @ObservedObject private var timelineTicker: MediaTimelineTicker
    @ObservedObject private var mediaGestureVisualModel: MediaGestureVisualModel
    @State private var sourceApplicationIcon: NSImage?
    @State private var seekPreviewSeconds: Double?
    @State private var isSeekDragging = false
    @State private var artworkTintColor = MediaNotchRootView.color(for: MediaArtworkTintCalculator.fallback)
    @Namespace private var artworkNamespace

    private let sourceApplicationIconResolver: SourceApplicationIconResolver
    private let onExplicitExpansion: () -> Void
    private let onTogglePlayPause: () -> Void
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private let onSeekBegan: () -> Bool
    private let onSeekCommitted: (Double) -> Void
    private let onSeekCancelled: () -> Void

    init(
        panelModel: NotchPanelModel,
        layoutModel: NotchPanelLayoutModel,
        mediaModel: ShippingMediaPresentationModel,
        mediaGestureVisualModel: MediaGestureVisualModel,
        sourceApplicationIconResolver: SourceApplicationIconResolver,
        onExplicitExpansion: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onSeekBegan: @escaping () -> Bool,
        onSeekCommitted: @escaping (Double) -> Void,
        onSeekCancelled: @escaping () -> Void,
        timelineTicker: MediaTimelineTicker
    ) {
        self.panelModel = panelModel
        self.layoutModel = layoutModel
        self.mediaModel = mediaModel
        self.timelineTicker = timelineTicker
        self.mediaGestureVisualModel = mediaGestureVisualModel
        self.sourceApplicationIconResolver = sourceApplicationIconResolver
        self.onExplicitExpansion = onExplicitExpansion
        self.onTogglePlayPause = onTogglePlayPause
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onSeekBegan = onSeekBegan
        self.onSeekCommitted = onSeekCommitted
        self.onSeekCancelled = onSeekCancelled
    }

    var body: some View {
        ZStack {
            if let presentation = mediaModel.presentation {
                mediaContent(presentation)
                    .transition(.opacity)
            } else {
                NotchRootView(
                    model: panelModel,
                    layoutModel: layoutModel,
                    handlesExplicitExpansionTap: false,
                    onExplicitExpansion: onExplicitExpansion
                )
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: requestExplicitExpansionFromTap)
        .animation(
            .easeInOut(duration: 0.12),
            value: mediaModel.presentation?.sessionIdentity
        )
        .animation(
            contentPresentationMorphAnimation,
            value: panelModel.contentPresentation
        )
        .onChange(of: isSeekSurfaceAvailable) { _, available in
            if !available {
                cancelSeekPreview()
            }
        }
        .onDisappear {
            cancelSeekPreview()
        }
    }

    private var hardwareNotchWidth: CGFloat {
        layoutModel.currentLayout.hardwareNotchWidth
    }

    private var expandedContentTopInset: CGFloat {
        layoutModel.currentLayout.expandedContentTopInset
    }

    private var peekContentTopInset: CGFloat {
        layoutModel.currentLayout.peekContentTopInset
    }

    /// Drives the `matchedGeometryEffect` artwork morph on `panelModel.contentPresentation`
    /// changes, kept in sync with the AppKit panel's own resize duration
    /// (`notchAnimationDuration`) so the artwork frame interpolation and the actual
    /// `NSPanel` frame animate over the same span. Reduce Motion disables the effect
    /// entirely, matching the zero-duration AppKit side.
    private var contentPresentationMorphAnimation: Animation? {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard !reduceMotion else {
            return nil
        }
        return .easeInOut(duration: notchAnimationDuration(reduceMotion: false))
    }

    private var isSeekSurfaceAvailable: Bool {
        let presentationAllowsSeek =
            panelModel.contentPresentation == .peek
            || panelModel.contentPresentation == .expanded
        guard
            presentationAllowsSeek,
            let presentation = mediaModel.presentation,
            presentation.canSeek,
            let position = presentation.positionSeconds,
            let duration = presentation.durationSeconds,
            position.isFinite,
            position >= 0,
            duration.isFinite,
            duration > 0,
            position <= duration
        else {
            return false
        }

        return true
    }

    @ViewBuilder
    private func mediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        Group {
            switch panelModel.contentPresentation {
            case .compact:
                compactMediaContent(presentation)
            case .peek:
                peekMediaContent(presentation)
            case .expanded:
                expandedMediaContent(presentation)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: mediaGestureVisualModel.horizontalOffset)
        .background(artworkTintColor)
        .animation(.easeInOut(duration: 0.4), value: artworkTintColor)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(surfaceAccessibilityIdentifier)
        .onChange(of: presentation.artworkData, initial: true) { _, artworkData in
            let tint = MediaArtworkTintSampler.sample(artworkData: artworkData) ?? MediaArtworkTintCalculator.fallback
            artworkTintColor = Self.color(for: tint)
        }
        .onChange(of: presentation.sourceBundleIdentifier, initial: true) { _, bundleIdentifier in
            if panelModel.contentPresentation == .expanded {
                sourceApplicationIcon = sourceApplicationIconResolver.icon(for: bundleIdentifier)
            }
        }
        .onChange(of: panelModel.contentPresentation) { _, panelPresentation in
            if panelPresentation == .expanded {
                sourceApplicationIcon = sourceApplicationIconResolver.icon(
                    for: presentation.sourceBundleIdentifier
                )
            }
        }
        .onChange(of: presentation.sessionIdentity) { _, _ in
            cancelSeekPreview()
        }
    }

    private var surfaceAccessibilityIdentifier: String {
        switch panelModel.contentPresentation {
        case .compact:
            "notch.surface.compact"
        case .peek:
            "notch.surface.peek"
        case .expanded:
            "notch.surface.expanded"
        }
    }

    /// Converts a `MediaArtworkTintCalculator.Tint` (already clamped to a
    /// legible range) into a SwiftUI `Color`. `MediaArtworkTintCalculator.fallback`
    /// converts to exactly `Color(hue: 0, saturation: 0, brightness: 0)`,
    /// i.e. flat black — identical to the pre-tint background.
    private static func color(for tint: MediaArtworkTintCalculator.Tint) -> Color {
        Color(hue: tint.hue, saturation: tint.saturation, brightness: tint.brightness)
    }

    private func requestExplicitExpansionFromTap() {
        guard panelModel.contentPresentation != .expanded else {
            return
        }
        onExplicitExpansion()
    }

    private func compactMediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        HStack(spacing: 0) {
            artwork(presentation, size: 24)
                .frame(width: 36, height: 32)

            Color.clear.frame(width: hardwareNotchWidth)

            MediaCompactEqualizerView(isPlaying: presentation.playbackState == .playing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private func peekMediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    artwork(presentation, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        MediaMarqueeText(
                            text: presentation.title ?? "Playing",
                            font: .subheadline.weight(.semibold),
                            color: .white
                        )
                        .accessibilityIdentifier("media.title")
                        MediaMarqueeText(
                            text: presentation.artist ?? "",
                            font: .caption,
                            color: .white.opacity(0.68)
                        )
                        .accessibilityIdentifier("media.artist")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(
                        systemName: presentation.playbackState == .playing
                            ? "waveform"
                            : "pause.fill"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 22)
                }

                if let position = presentation.positionSeconds,
                    let duration = presentation.durationSeconds
                {
                    seekProgress(
                        position: timelineTicker.displayedPositionSeconds ?? position,
                        duration: duration,
                        canSeek: presentation.canSeek
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, peekContentTopInset)
            .padding(.bottom, 10)
        }
    }

    private func expandedMediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                artworkWithSourceBadge(presentation, size: 92)

                VStack(alignment: .leading, spacing: 5) {
                    if let title = presentation.title {
                        MediaMarqueeText(text: title, font: .headline, color: .white)
                            .accessibilityIdentifier("media.title")
                    }
                    if let artist = presentation.artist {
                        MediaMarqueeText(
                            text: artist,
                            font: .subheadline,
                            color: .white.opacity(0.75)
                        )
                        .accessibilityIdentifier("media.artist")
                    }
                    if let album = presentation.album {
                        MediaMarqueeText(text: album, font: .caption, color: .white.opacity(0.5))
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            }

            if let position = presentation.positionSeconds,
                let duration = presentation.durationSeconds
            {
                seekProgress(
                    position: timelineTicker.displayedPositionSeconds ?? position,
                    duration: duration,
                    canSeek: presentation.canSeek
                )
            }

            HStack(spacing: 28) {
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(!presentation.canGoPrevious)
                .opacity(presentation.canGoPrevious ? 1 : 0.3)
                .accessibilityIdentifier("media.previous")
                .accessibilityValue(presentation.canGoPrevious ? "enabled" : "disabled")

                Button(action: onTogglePlayPause) {
                    Image(
                        systemName: presentation.playbackState == .playing
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(.title2)
                    .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("media.playPause")
                .accessibilityValue(
                    presentation.playbackState == .playing ? "playing" : "paused"
                )

                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(!presentation.canGoNext)
                .opacity(presentation.canGoNext ? 1 : 0.3)
                .accessibilityIdentifier("media.next")
                .accessibilityValue(presentation.canGoNext ? "enabled" : "disabled")
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
        .padding(.top, expandedContentTopInset)
    }

    private func seekProgress(
        position: Double,
        duration: Double,
        canSeek: Bool
    ) -> some View {
        GeometryReader { geometry in
            ProgressView(
                value: seekPreviewSeconds ?? position,
                total: duration
            )
            .progressViewStyle(.linear)
            .tint(.white.opacity(0.85))
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard canSeek else {
                            cancelSeekPreview()
                            return
                        }

                        if !isSeekDragging {
                            guard onSeekBegan() else {
                                return
                            }
                            isSeekDragging = true
                        }

                        seekPreviewSeconds = seekPosition(
                            locationX: value.location.x,
                            width: geometry.size.width,
                            duration: duration
                        )
                    }
                    .onEnded { value in
                        guard isSeekDragging else {
                            return
                        }

                        let positionSeconds = seekPosition(
                            locationX: value.location.x,
                            width: geometry.size.width,
                            duration: duration
                        )
                        isSeekDragging = false
                        seekPreviewSeconds = nil
                        onSeekCommitted(positionSeconds)
                    }
            )
        }
        .frame(height: 8)
        .opacity(canSeek ? 1 : 0.55)
        .allowsHitTesting(canSeek)
    }

    private func seekPosition(
        locationX: CGFloat,
        width: CGFloat,
        duration: Double
    ) -> Double {
        guard
            locationX.isFinite,
            width.isFinite,
            width > 0,
            duration.isFinite,
            duration > 0
        else {
            return 0
        }

        let clampedX = min(max(0, locationX), width)
        return Double(clampedX / width) * duration
    }

    private func cancelSeekPreview() {
        guard isSeekDragging || seekPreviewSeconds != nil else {
            return
        }

        isSeekDragging = false
        seekPreviewSeconds = nil
        onSeekCancelled()
    }

    private func artworkWithSourceBadge(
        _ presentation: ShippingMediaPresentation,
        size: CGFloat
    ) -> some View {
        artwork(presentation, size: size)
            .overlay(alignment: .bottomTrailing) {
                sourceApplicationBadge(presentation)
                    .offset(x: 4, y: 4)
            }
    }

    private func sourceApplicationBadge(_ presentation: ShippingMediaPresentation) -> some View {
        Group {
            if let sourceApplicationIcon {
                Image(nsImage: sourceApplicationIcon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 24, height: 24)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.75))
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityIdentifier("media.source")
        .accessibilityLabel(Text(presentation.sourceDisplayName))
    }

    private func artwork(
        _ presentation: ShippingMediaPresentation,
        size: CGFloat
    ) -> some View {
        Group {
            if let artworkData = presentation.artworkData,
                let image = NSImage(data: artworkData)
            {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: size >= 60 ? 16 : 7, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(size >= 60 ? .title : .caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(
                cornerRadius: size >= 60 ? 16 : 7,
                style: .continuous
            )
        )
        .matchedGeometryEffect(id: "media.artwork", in: artworkNamespace)
        .accessibilityIdentifier("media.artwork")
    }
}
