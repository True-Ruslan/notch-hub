import AppKit
import NotchHubCore
import NotchHubMediaCore
import SwiftUI

@MainActor
struct MediaNotchRootView: View {
    @ObservedObject private var panelModel: NotchPanelModel
    @ObservedObject private var mediaModel: ShippingMediaPresentationModel
    @ObservedObject private var mediaGestureVisualModel: MediaGestureVisualModel
    @State private var sourceApplicationIcon: NSImage?
    @State private var seekPreviewSeconds: Double?
    @State private var isSeekDragging = false

    private let sourceApplicationIconResolver: SourceApplicationIconResolver
    private let hardwareNotchWidth: CGFloat
    private let compactBackgroundOpacity: Double
    private let expandedContentTopInset: CGFloat
    private let onExplicitExpansion: () -> Void
    private let onTogglePlayPause: () -> Void
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private let onSeekBegan: () -> Bool
    private let onSeekCommitted: (Double) -> Void
    private let onSeekCancelled: () -> Void

    init(
        panelModel: NotchPanelModel,
        mediaModel: ShippingMediaPresentationModel,
        mediaGestureVisualModel: MediaGestureVisualModel,
        sourceApplicationIconResolver: SourceApplicationIconResolver,
        hardwareNotchWidth: CGFloat,
        compactBackgroundOpacity: Double,
        expandedContentTopInset: CGFloat,
        onExplicitExpansion: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onSeekBegan: @escaping () -> Bool,
        onSeekCommitted: @escaping (Double) -> Void,
        onSeekCancelled: @escaping () -> Void
    ) {
        self.panelModel = panelModel
        self.mediaModel = mediaModel
        self.mediaGestureVisualModel = mediaGestureVisualModel
        self.sourceApplicationIconResolver = sourceApplicationIconResolver
        self.hardwareNotchWidth = hardwareNotchWidth
        self.compactBackgroundOpacity = compactBackgroundOpacity
        self.expandedContentTopInset = expandedContentTopInset
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
                    compactBackgroundOpacity: compactBackgroundOpacity,
                    expandedContentTopInset: expandedContentTopInset,
                    onExplicitExpansion: onExplicitExpansion
                )
                .transition(.opacity)
            }
        }
        .animation(
            .easeInOut(duration: 0.12),
            value: mediaModel.presentation?.sessionIdentity
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
        .background(Color.black)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(surfaceAccessibilityIdentifier)
        .onTapGesture(perform: requestExplicitExpansionFromTap)
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

            Image(
                systemName: presentation.playbackState == .playing
                    ? "waveform"
                    : "pause.fill"
            )
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(presentation.playbackState == .playing ? 0.9 : 0.6))
            .frame(width: 36, height: 32)
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
                        Text(presentation.title ?? "Playing")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityIdentifier("media.title")
                        Text(presentation.artist ?? "")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .truncationMode(.tail)
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
                        position: position,
                        duration: duration,
                        canSeek: presentation.canSeek
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 28)
            .padding(.bottom, 10)
        }
    }

    private func expandedMediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                artworkWithSourceBadge(presentation, size: 92)

                VStack(alignment: .leading, spacing: 5) {
                    if let title = presentation.title {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .accessibilityIdentifier("media.title")
                    }
                    if let artist = presentation.artist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                            .accessibilityIdentifier("media.artist")
                    }
                    if let album = presentation.album {
                        Text(album)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            }

            if let position = presentation.positionSeconds,
                let duration = presentation.durationSeconds
            {
                seekProgress(
                    position: position,
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
        .accessibilityIdentifier("media.artwork")
    }
}
