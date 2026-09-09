import NotchHubCore
import NotchHubMediaCore
import SwiftUI

@MainActor
struct ProductRoutingRootView<HomeContent: View, ShelfContent: View, SnippetsContent: View>: View {
    @ObservedObject private var panelModel: NotchPanelModel
    @ObservedObject private var layoutModel: NotchPanelLayoutModel
    @ObservedObject private var mediaModel: ShippingMediaPresentationModel
    @ObservedObject private var destinationModel: NotchDestinationModel

    private let homeContent: HomeContent
    private let shelfContent: ShelfContent
    private let snippetsContent: SnippetsContent

    init(
        panelModel: NotchPanelModel,
        layoutModel: NotchPanelLayoutModel,
        mediaModel: ShippingMediaPresentationModel,
        destinationModel: NotchDestinationModel,
        @ViewBuilder shelfContent: () -> ShelfContent,
        @ViewBuilder snippetsContent: () -> SnippetsContent,
        @ViewBuilder homeContent: () -> HomeContent
    ) {
        self.panelModel = panelModel
        self.layoutModel = layoutModel
        self.mediaModel = mediaModel
        self.destinationModel = destinationModel
        self.shelfContent = shelfContent()
        self.snippetsContent = snippetsContent()
        self.homeContent = homeContent()
    }

    var body: some View {
        ZStack {
            if panelModel.contentPresentation == .expanded,
                destinationModel.destination == .shelf
            {
                shelfContent
            } else if panelModel.contentPresentation == .expanded,
                destinationModel.destination == .snippets
            {
                snippetsContent
            } else {
                homeContent
                    .environment(
                        \.notchSelectShelfAction,
                        NotchSelectShelfAction {
                            destinationModel.select(.shelf)
                        }
                    )
                    .environment(
                        \.notchSelectSnippetsAction,
                        NotchSelectSnippetsAction {
                            destinationModel.select(.snippets)
                        }
                    )
                    .overlay(alignment: .topTrailing) {
                        if panelModel.contentPresentation == .expanded,
                            mediaModel.presentation != nil
                        {
                            HStack(spacing: 8) {
                                Button {
                                    destinationModel.select(.shelf)
                                } label: {
                                    Label("Shelf", systemImage: "tray.full")
                                        .font(.caption.weight(.semibold))
                                }
                                .accessibilityIdentifier("media.openShelf")

                                Button {
                                    destinationModel.select(.snippets)
                                } label: {
                                    Label("Snippets", systemImage: "text.badge.plus")
                                        .font(.caption.weight(.semibold))
                                }
                                .accessibilityIdentifier("media.openSnippets")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                .black.opacity(0.34),
                                in: Capsule()
                            )
                            .padding(.top, layoutModel.currentLayout.expandedContentTopInset + 4)
                            .padding(.trailing, 14)
                        }
                    }
            }
        }
        .onChange(of: panelModel.contentPresentation) { _, presentation in
            if presentation != .expanded {
                destinationModel.reset()
            }
        }
    }
}
