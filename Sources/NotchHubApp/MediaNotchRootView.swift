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
        self.onTogglePlayPause = onTogglePlayPause
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onSeekBegan = onSeekBegan
        self.onSeekCommitted = onSeekCommitted
        self.onSeekCancelled = onSeekCancelled
    }

    var body: some View {
        Group {
            if let presentation = mediaModel.presentation {
                mediaContent(presentation)
            } else {
                NotchRootView(
                    model: panelModel,
                    compactBackgroundOpacity: compactBackgroundOpacity,
                    expandedContentTopInset: expandedContentTopInset
                )
            }
        }
        .onDisappear {
            cancelSeekPreview()
        }
    }

    @ViewBuilder
    private func mediaContent(_ presentation: ShippingMediaPresentation) -> some View {
        Group {
            switch panelModel.contentPresentation {
            case .compact:
                compactMediaContent(presentation)
            case .expanded:
                expandedMediaContent(presentation)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: mediaGestureVisualModel.horizontalOffset)
        .background(Color.black)
        .contentShape(Rectangle())
        .onChange(of: presentation.sourceBundleIdentifier, initial: true) { _, bundleIdentifier in
            sourceApplicationIcon = sourceApplicationIconResolver.icon(for: bundleIdentifier)
        }
        .onChange(of: presentation.canSeek) { _, canSeek in
            if !canSeek {
                cancelSeekPreview()
            }
        }
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
                    }
                    if let artist = presentation.artist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
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

                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(!presentation.canGoNext)
                .opacity(presentation.canGoNext ? 1 : 0.3)
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
            .gesture(
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
    }
}
