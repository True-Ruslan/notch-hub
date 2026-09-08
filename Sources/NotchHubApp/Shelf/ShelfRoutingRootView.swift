import NotchHubCore
import NotchHubMediaCore
import SwiftUI

@MainActor
struct ShelfRoutingRootView<HomeContent: View>: View {
    @ObservedObject private var panelModel: NotchPanelModel
    @ObservedObject private var layoutModel: NotchPanelLayoutModel
    @ObservedObject private var mediaModel: ShippingMediaPresentationModel
    @ObservedObject private var destinationModel: NotchDestinationModel
    @ObservedObject private var shelfStore: ShelfStore

    private let quickLookController: ShelfQuickLookController
    private let homeContent: HomeContent

    init(
        panelModel: NotchPanelModel,
        layoutModel: NotchPanelLayoutModel,
        mediaModel: ShippingMediaPresentationModel,
        destinationModel: NotchDestinationModel,
        shelfStore: ShelfStore,
        quickLookController: ShelfQuickLookController,
        @ViewBuilder homeContent: () -> HomeContent
    ) {
        self.panelModel = panelModel
        self.layoutModel = layoutModel
        self.mediaModel = mediaModel
        self.destinationModel = destinationModel
        self.shelfStore = shelfStore
        self.quickLookController = quickLookController
        self.homeContent = homeContent()
    }

    var body: some View {
        ZStack {
            if panelModel.contentPresentation == .expanded,
                destinationModel.destination == .shelf
            {
                ShelfView(
                    store: shelfStore,
                    quickLookController: quickLookController,
                    topInset: layoutModel.currentLayout.expandedContentTopInset,
                    onHome: destinationModel.reset
                )
            } else {
                homeContent
                    .environment(
                        \.notchSelectShelfAction,
                        NotchSelectShelfAction {
                            destinationModel.select(.shelf)
                        }
                    )
                    .overlay(alignment: .topTrailing) {
                        if panelModel.contentPresentation == .expanded,
                            mediaModel.presentation != nil
                        {
                            Button {
                                destinationModel.select(.shelf)
                            } label: {
                                Label("Shelf", systemImage: "tray.full")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        .black.opacity(0.34),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.9))
                            .accessibilityIdentifier("media.openShelf")
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
