import AppKit
import NotchHubCore
import NotchHubMediaCore
import SwiftUI

@MainActor
struct MediaNotchRootView: View {
    @ObservedObject private var panelModel: NotchPanelModel
    @ObservedObject private var mediaModel: ShippingMediaPresentationModel

    private let hardwareNotchWidth: CGFloat
    private let compactBackgroundOpacity: Double
    private let expandedContentTopInset: CGFloat
    private let onTogglePlayPause: () -> Void
    private let onPrevious: () -> Void
    private let onNext: () -> Void

    init(
        panelModel: NotchPanelModel,
        mediaModel: ShippingMediaPresentationModel,
        hardwareNotchWidth: CGFloat,
        compactBackgroundOpacity: Double,
        expandedContentTopInset: CGFloat,
        onTogglePlayPause: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.panelModel = panelModel
        self.mediaModel = mediaModel
        self.hardwareNotchWidth = hardwareNotchWidth
        self.compactBackgroundOpacity = compactBackgroundOpacity
        self.expandedContentTopInset = expandedContentTopInset
        self.onTogglePlayPause = onTogglePlayPause
        self.onPrevious = onPrevious
        self.onNext = onNext
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
        .background(Color.black)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(surfaceAccessibilityIdentifier)
    }

    private var surfaceAccessibilityIdentifier: String {
        switch panelModel.contentPresentation {
        case .compact:
            "notch.surface.compact"
        case .expanded:
            "notch.surface.expanded"
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
                artwork(presentation, size: 92)

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

                    Text(presentation.sourceDisplayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                        .accessibilityIdentifier("media.source")
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            }

            if let position = presentation.positionSeconds,
                let duration = presentation.durationSeconds
            {
                ProgressView(value: position, total: duration)
                    .progressViewStyle(.linear)
                    .tint(.white.opacity(0.85))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Media artwork")
        .accessibilityIdentifier("media.artwork")
    }
}