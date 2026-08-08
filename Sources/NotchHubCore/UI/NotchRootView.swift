import SwiftUI

public struct NotchRootView: View {
    @ObservedObject private var model: NotchPanelModel
    private let visualMetrics: NotchVisualMetrics

    public init(model: NotchPanelModel) {
        self.init(
            model: model,
            visualMetrics: NotchVisualLayoutPolicy.metrics(
                hasHardwareNotch: false,
                compactHeight: 32
            )
        )
    }

    init(model: NotchPanelModel, visualMetrics: NotchVisualMetrics) {
        self.model = model
        self.visualMetrics = visualMetrics
    }

    public var body: some View {
        Group {
            switch model.presentation {
            case .compact:
                compactContent
            case .expanded:
                expandedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surfaceBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: model.presentation == .compact ? 12 : 22,
                style: .continuous
            )
        )
        .contentShape(Rectangle())
        .animation(.snappy(duration: 0.22), value: model.presentation)
    }

    private var surfaceBackground: Color {
        switch model.presentation {
        case .compact:
            Color.black.opacity(visualMetrics.compactBackgroundOpacity)
        case .expanded:
            Color.black
        }
    }

    private var compactContent: some View {
        HStack(spacing: 6) {
            Spacer()
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 4, height: 4)
            Spacer()
        }
        .padding(.top, 3)
    }

    private var expandedContent: some View {
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
        .padding(.top, visualMetrics.expandedContentTopInset)
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
