import NotchHubCore
import NotchHubMediaCore

@MainActor
final class MediaPeekSession {
    private let probe: ShippingMediaPeekProbe
    private let presentationModel: ShippingMediaPresentationModel
    private weak var panelController: NotchPanelController?

    private var activeRequest: NotchHoverPeekRequest?
    private var generation: UInt64 = 0
    private var isInvalidated = false

    init(
        probe: ShippingMediaPeekProbe,
        presentationModel: ShippingMediaPresentationModel,
        panelController: NotchPanelController
    ) {
        self.probe = probe
        self.presentationModel = presentationModel
        self.panelController = panelController
    }

    func handleHoverRequest(_ request: NotchHoverPeekRequest) {
        guard !isInvalidated, let panelController else {
            return
        }

        cancelProbeOnly()
        generation &+= 1
        let expectedGeneration = generation
        activeRequest = request

        if presentationModel.presentation != nil {
            panelController.resolveHoverPeekRequest(request, mediaAvailable: true)
        }

        probe.acquire { [weak self] result in
            self?.finishProbe(
                result,
                for: request,
                expectedGeneration: expectedGeneration
            )
        }
    }

    func cancel() {
        guard !isInvalidated else {
            return
        }

        generation &+= 1
        activeRequest = nil
        probe.cancel()
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        generation &+= 1
        activeRequest = nil
        probe.cancel()
        panelController = nil
        isInvalidated = true
    }

    private func cancelProbeOnly() {
        probe.cancel()
    }

    private func finishProbe(
        _ result: ShippingMediaPeekProbe.Result,
        for request: NotchHoverPeekRequest,
        expectedGeneration: UInt64
    ) {
        guard
            !isInvalidated,
            generation == expectedGeneration,
            activeRequest == request,
            let panelController
        else {
            return
        }

        activeRequest = nil

        switch result {
        case .presentation(let presentation):
            presentationModel.applyOneShotPresentation(presentation)
            panelController.resolveHoverPeekRequest(request, mediaAvailable: true)

        case .noSession:
            presentationModel.clearAuthoritativePresentation()
            panelController.resolveHoverPeekRequest(request, mediaAvailable: false)
            panelController.requestCollapse()

        case .failed:
            panelController.resolveHoverPeekRequest(request, mediaAvailable: false)
        }
    }
}
