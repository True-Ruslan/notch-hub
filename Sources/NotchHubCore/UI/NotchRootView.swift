import SwiftUI

public struct NotchRootView: View {
    @ObservedObject private var model: NotchPanelModel
    @ObservedObject private var layoutModel: NotchPanelLayoutModel
    private let handlesExplicitExpansionTap: Bool
    private let onExplicitExpansion: () -> Void

    public init(
        model: NotchPanelModel,
        layoutModel: NotchPanelLayoutModel,
        handlesExplicitExpansionTap: Bool = true,
        onExplicitExpansion: @escaping () -> Void = {}
    ) {
        self.model = model
        self.layoutModel = layoutModel
        self.handlesExplicitExpansionTap = handlesExplicitExpansionTap
        self.onExplicitExpansion = onExplicitExpansion
    }

    public var body: some View {
        if handlesExplicitExpansionTap {
            surfaceContent
                .onTapGesture(perform: requestExplicitExpansionFromTap)
        } else {
            surfaceContent
        }
    }

    private var surfaceContent: some View {
        Group {
            switch model.contentPresentation {
            case .compact, .peek:
                compactContent
            case .expanded:
                expandedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            model.contentPresentation == .compact
                ? Color.black.opacity(layoutModel.currentLayout.compactBackgroundOpacity)
                : Color.black
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(surfaceAccessibilityIdentifier)
    }

    private var surfaceAccessibilityIdentifier: String {
        switch model.contentPresentation {
        case .compact:
            "notch.surface.compact"
        case .peek:
            "notch.surface.peek"
        case .expanded:
            "notch.surface.expanded"
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

            Text("Use the upward gesture to collapse")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, layoutModel.currentLayout.expandedContentTopInset)
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

    private func requestExplicitExpansionFromTap() {
        guard model.contentPresentation != .expanded else {
            return
        }
        onExplicitExpansion()
    }
}
