import AppKit
import NotchHubCore
import NotchHubMediaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let mediaCompactWingWidth: CGFloat = 36

    private var panelController: NotchPanelController?
    private var mediaRuntime: (any MediaRuntimeSession)?
    private let mediaPresentationModel = ShippingMediaPresentationModel()
    private let mediaGestureVisualModel = MediaGestureVisualModel()
    private let sourceApplicationIconResolver = SourceApplicationIconResolver()
    private var mediaGestureSession: MediaGestureSession?
    private var mediaPeekSession: MediaPeekSession?
    private let composition: AppComposition = {
        #if NOTCHHUB_UI_TESTING
            AppComposition.uiTesting(configuration: .current())
        #else
            AppComposition.shipping()
        #endif
    }()

    #if NOTCHHUB_UI_TESTING
        private let uiTestHapticRecorder = UITestHapticRecorder()
    #endif

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let mediaPresentationModel = mediaPresentationModel
        let mediaGestureVisualModel = mediaGestureVisualModel
        let sourceApplicationIconResolver = sourceApplicationIconResolver

        let mediaGestureSession: MediaGestureSession
        #if NOTCHHUB_UI_TESTING
            let gestureHapticRecorder = uiTestHapticRecorder
            mediaGestureSession = MediaGestureSession(
                compactDispatcher: ShippingMediaCompactCommandDispatcher(),
                visualModel: mediaGestureVisualModel,
                performArmHaptic: {
                    gestureHapticRecorder.performExpansionHaptic()
                }
            )
        #else
            mediaGestureSession = MediaGestureSession(
                compactDispatcher: ShippingMediaCompactCommandDispatcher(),
                visualModel: mediaGestureVisualModel,
                performArmHaptic: {
                    NSHapticFeedbackManager.defaultPerformer.perform(
                        .levelChange,
                        performanceTime: .now
                    )
                }
            )
        #endif
        self.mediaGestureSession = mediaGestureSession

        var capturedPanelModel: NotchPanelModel?
        let contentFactory: NotchPanelContentFactory = { [weak self, weak mediaGestureSession] model, layout in
            capturedPanelModel = model
            return NotchHostingViewFactory.make(
                rootView: MediaNotchRootView(
                    panelModel: model,
                    mediaModel: mediaPresentationModel,
                    mediaGestureVisualModel: mediaGestureVisualModel,
                    sourceApplicationIconResolver: sourceApplicationIconResolver,
                    hardwareNotchWidth: layout.hardwareNotchWidth,
                    compactBackgroundOpacity: layout.compactBackgroundOpacity,
                    expandedContentTopInset: layout.expandedContentTopInset,
                    onExplicitExpansion: { [weak self] in
                        self?.panelController?.requestExpansion()
                    },
                    onTogglePlayPause: { [weak self] in
                        self?.mediaRuntime?.togglePlayPause()
                    },
                    onPrevious: { [weak self] in
                        self?.mediaRuntime?.goPrevious()
                    },
                    onNext: { [weak self] in
                        self?.mediaRuntime?.goNext()
                    },
                    onSeekBegan: { [weak mediaGestureSession] in
                        mediaGestureSession?.beginSeek() ?? false
                    },
                    onSeekCommitted: { [weak mediaGestureSession] positionSeconds in
                        mediaGestureSession?.commitSeek(to: positionSeconds)
                    },
                    onSeekCancelled: { [weak mediaGestureSession] in
                        mediaGestureSession?.cancelSeek()
                    }
                ),
                onScrollWheel: { [weak mediaGestureSession] event in
                    mediaGestureSession?.handleScrollWheel(event)
                }
            )
        }

        let panelController: NotchPanelController
        #if NOTCHHUB_UI_TESTING
            let panelHapticRecorder = uiTestHapticRecorder
            panelController = NotchPanelController(
                contentFactory: contentFactory,
                performExpansionHaptic: {
                    panelHapticRecorder.performExpansionHaptic()
                }
            )
        #else
            panelController = NotchPanelController(contentFactory: contentFactory)
        #endif
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

        let mediaPeekSession = MediaPeekSession(
            probe: ShippingMediaPeekProbe(),
            presentationModel: mediaPresentationModel,
            panelController: panelController
        )
        self.mediaPeekSession = mediaPeekSession
        panelController.hoverPeekRequestHandler = { [weak mediaPeekSession] request in
            mediaPeekSession?.handleHoverRequest(request)
        }

        mediaPresentationModel.presentationDidChange = { [weak panelController] presentation in
            panelController?.setCompactHorizontalExtension(
                presentation == nil ? 0 : Self.mediaCompactWingWidth
            )
        }

        panelController.settledPresentationHandler = { [weak self, weak mediaPeekSession] presentation in
            if presentation != .peek, let mediaPeekSession {
                mediaPeekSession.cancel()
            }
            self?.updateMediaRuntime(for: presentation)
        }
        panelController.show()
    }

    func applicationDidResignActive(_: Notification) {
        mediaGestureSession?.cancelSeek()
    }

    func applicationWillTerminate(_: Notification) {
        panelController?.settledPresentationHandler = nil
        panelController?.hoverPeekRequestHandler = nil
        mediaPresentationModel.presentationDidChange = nil

        if let mediaPeekSession {
            mediaPeekSession.invalidate()
        }
        mediaPeekSession = nil

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

            let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)
            self.mediaRuntime = mediaRuntime
            mediaRuntime.start()

        case .compact, .peek:
            mediaRuntime?.stop()
            mediaRuntime = nil
        }
    }
}
