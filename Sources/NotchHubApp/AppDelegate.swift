import AppKit
import NotchHubCore
import NotchHubMediaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let mediaCompactWingWidth: CGFloat = 36

    private var panelController: NotchPanelController?
    private var mediaRuntime: (any MediaRuntimeSession)?
    private let mediaPresentationModel = ShippingMediaPresentationModel()
    private let composition: AppComposition = {
        #if NOTCHHUB_UI_TESTING
            AppComposition.uiTesting(configuration: .current())
        #else
            AppComposition.shipping()
        #endif
    }()

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let mediaPresentationModel = mediaPresentationModel
        let panelController = NotchPanelController(contentFactory: { [weak self] model, layout in
            NotchHostingViewFactory.make(
                rootView: MediaNotchRootView(
                    panelModel: model,
                    mediaModel: mediaPresentationModel,
                    hardwareNotchWidth: layout.hardwareNotchWidth,
                    compactBackgroundOpacity: layout.compactBackgroundOpacity,
                    expandedContentTopInset: layout.expandedContentTopInset,
                    onTogglePlayPause: { [weak self] in
                        self?.mediaRuntime?.togglePlayPause()
                    },
                    onPrevious: { [weak self] in
                        self?.mediaRuntime?.goPrevious()
                    },
                    onNext: { [weak self] in
                        self?.mediaRuntime?.goNext()
                    }
                )
            )
        })
        self.panelController = panelController

        mediaPresentationModel.presentationDidChange = { [weak panelController] presentation in
            panelController?.setCompactHorizontalExtension(
                presentation == nil ? 0 : Self.mediaCompactWingWidth
            )
        }

        panelController.settledPresentationHandler = { [weak self] presentation in
            self?.updateMediaRuntime(for: presentation)
        }
        panelController.show()
    }

    func applicationWillTerminate(_: Notification) {
        panelController?.settledPresentationHandler = nil
        mediaPresentationModel.presentationDidChange = nil

        mediaRuntime?.stop()
        mediaRuntime = nil

        panelController?.invalidate()
        panelController = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }

    private func updateMediaRuntime(for presentation: NotchPresentation) {
        switch presentation {
        case .expanded:
            guard mediaRuntime == nil else {
                return
            }

            let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)
            self.mediaRuntime = mediaRuntime
            mediaRuntime.start()

        case .compact:
            mediaRuntime?.stop()
            mediaRuntime = nil
        }
    }
}
