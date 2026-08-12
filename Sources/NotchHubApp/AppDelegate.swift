import AppKit
import NotchHubCore
import NotchHubMediaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let mediaCompactWingWidth: CGFloat = 36

    private var panelController: NotchPanelController?
    private var mediaRuntime: ShippingMediaRuntime?
    private let mediaPresentationModel = ShippingMediaPresentationModel()
    private let mediaGestureVisualModel = MediaGestureVisualModel()
    private var mediaGestureSession: MediaGestureSession?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let mediaPresentationModel = mediaPresentationModel
        let mediaGestureVisualModel = mediaGestureVisualModel
        let mediaGestureSession = MediaGestureSession(
            compactDispatcher: ShippingMediaCompactCommandDispatcher(),
            visualModel: mediaGestureVisualModel,
            performArmHaptic: {
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .now
                )
            }
        )
        self.mediaGestureSession = mediaGestureSession

        var capturedPanelModel: NotchPanelModel?
        let panelController = NotchPanelController(contentFactory: { [weak self, weak mediaGestureSession] model, layout in
            capturedPanelModel = model
            return NotchHostingViewFactory.make(
                rootView: MediaNotchRootView(
                    panelModel: model,
                    mediaModel: mediaPresentationModel,
                    mediaGestureVisualModel: mediaGestureVisualModel,
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
                ),
                onScrollWheel: { [weak mediaGestureSession] event in
                    mediaGestureSession?.handleScrollWheel(event)
                }
            )
        })
        self.panelController = panelController

        if let capturedPanelModel {
            mediaGestureSession.bind(
                panelController: panelController,
                panelModel: capturedPanelModel,
                runtimeProvider: { [weak self] in
                    self?.mediaRuntime
                },
                presentationProvider: { [weak mediaPresentationModel] in
                    mediaPresentationModel?.presentation
                }
            )
        }

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

        mediaGestureSession?.invalidate()
        mediaGestureSession = nil

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

            let mediaRuntime = ShippingMediaRuntime(presentationModel: mediaPresentationModel)
            self.mediaRuntime = mediaRuntime
            mediaRuntime.start()

        case .compact:
            mediaRuntime?.stop()
            mediaRuntime = nil
        }
    }
}
