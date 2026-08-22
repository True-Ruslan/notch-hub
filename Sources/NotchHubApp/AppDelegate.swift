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
    private lazy var mediaTimelineTicker = composition.makeMediaTimelineTicker()

    #if NOTCHHUB_UI_TESTING
        private let uiTestHapticRecorder = UITestHapticRecorder()
    #endif

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let mediaPresentationModel = mediaPresentationModel
        let mediaTimelineTicker = mediaTimelineTicker
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

        #if NOTCHHUB_UI_TESTING
            let hapticDiagnosticsRecorder = uiTestHapticRecorder
        #endif

        var capturedPanelModel: NotchPanelModel?
        let contentFactory: NotchPanelContentFactory = {
            [weak self, weak mediaGestureSession] model, layoutModel in
            capturedPanelModel = model
            let mediaRoot = MediaNotchRootView(
                panelModel: model,
                layoutModel: layoutModel,
                mediaModel: mediaPresentationModel,
                mediaGestureVisualModel: mediaGestureVisualModel,
                sourceApplicationIconResolver: sourceApplicationIconResolver,
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
                onSeekCommitted: { [weak self, weak mediaGestureSession] positionSeconds in
                    self?.mediaTimelineTicker.applyOptimisticSeek(to: positionSeconds)
                    mediaGestureSession?.commitSeek(to: positionSeconds)
                },
                onSeekCancelled: { [weak mediaGestureSession] in
                    mediaGestureSession?.cancelSeek()
                },
                timelineTicker: mediaTimelineTicker
            )

            #if NOTCHHUB_UI_TESTING
                return NotchHostingViewFactory.make(
                    rootView: UITestHapticDiagnosticsView(
                        recorder: hapticDiagnosticsRecorder
                    ) {
                        mediaRoot
                    },
                    onScrollWheel: { [weak mediaGestureSession] event in
                        mediaGestureSession?.handleScrollWheel(event)
                    }
                )
            #else
                return NotchHostingViewFactory.make(
                    rootView: mediaRoot,
                    onScrollWheel: { [weak mediaGestureSession] event in
                        mediaGestureSession?.handleScrollWheel(event)
                    }
                )
            #endif
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
            probe: composition.makeMediaPeekProbe(),
            presentationModel: mediaPresentationModel,
            panelController: panelController
        )
        self.mediaPeekSession = mediaPeekSession
        panelController.hoverPeekRequestHandler = { [weak mediaPeekSession] request in
            mediaPeekSession?.handleHoverRequest(request)
        }

        mediaPresentationModel.presentationDidChange = { [weak self, weak panelController] presentation in
            panelController?.setCompactHorizontalExtension(
                presentation == nil ? 0 : Self.mediaCompactWingWidth
            )
            self?.mediaTimelineTicker.apply(presentation: presentation)
        }

        panelController.settledPresentationHandler = { [weak self, weak mediaPeekSession] presentation in
            if let mediaPeekSession {
                switch presentation {
                case .peek:
                    mediaPeekSession.handleSettledPeek()
                case .compact, .expanded:
                    mediaPeekSession.cancel()
                }
            }
            self?.mediaTimelineTicker.setArmed(presentation == .peek || presentation == .expanded)
        }

        panelController.show()

        let mediaRuntime = composition.makeMediaRuntime(mediaPresentationModel)
        self.mediaRuntime = mediaRuntime
        mediaRuntime.start()
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

        mediaTimelineTicker.invalidate()

        mediaRuntime?.stop()
        mediaRuntime = nil

        panelController?.invalidate()
        panelController = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }
}
