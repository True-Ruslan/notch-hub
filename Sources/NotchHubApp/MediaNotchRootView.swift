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
            switch panelModel.contentPresentation {
            case .compact:
                compactContent
            case .expanded:
                expandedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            panelModel.contentPresentation == .compact
                ? Color.black.opacity(compactBackgroundOpacity)
                : Color.black
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var compactContent: some View {
        if let presentation = mediaModel.presentation {
            compactMediaContent(presentation)
        } else {
            ordinaryCompactContent
        }
    }

    private var ordinaryCompactContent: some View {
        HStack(spacing: 6) {
            Spacer()
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 4, height: 4)
            Spacer()
        }
        .padding(.top, 3)
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

    @ViewBuilder
    private var expandedContent: some View {
        if let presentation = mediaModel.presentation {
            expandedMediaContent(presentation)
        } else {
            homeContent
        }
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

                    Text(presentation.sourceDisplayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
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

    private var homeContent: some View {
        VStack(spacing: 16) {
            HStack {
                Text("NotchHub")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Foundation preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                moduleTile("Music", systemImage: "music.note")
                moduleTile("Shelf", systemImage: "tray.full")
                moduleTile("Snippets", systemImage: "text.badge.plus")
                moduleTile("Calendar", systemImage: "calendar")
                moduleTile("Translate", systemImage: "character.bubble")
            }

            Spacer(minLength: 0)

            Text("Move the pointer away to collapse")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
    }

    private func moduleTile(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(
            .white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
