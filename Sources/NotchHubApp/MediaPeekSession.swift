import NotchHubCore
import NotchHubMediaCore

@MainActor
final class MediaPeekSession {
    private let probe: any MediaPeekProbing
    private let presentationModel: ShippingMediaPresentationModel
    private weak var panelController: NotchPanelController?

    private var generation: UInt64 = 0
    private var activeRequest: NotchHoverPeekRequest?
    private var probingRequest: NotchHoverPeekRequest?
    private var isInvalidated = false

    init(
        probe: any MediaPeekProbing,
        presentationModel: ShippingMediaPresentationModel,
        panelController: NotchPanelController
    ) {
        self.probe = probe
        self.presentationModel = presentationModel
        self.panelController = panelController
    }

    func handleHoverRequest(_ request: NotchHoverPeekRequest) {
        guard !isInvalidated else {
            return
        }

        cancelActiveProbe()
        generation &+= 1
        activeRequest = request

        panelController?.resolveHoverPeekRequest(request, mediaAvailable: false)
    }

    func handleSettledPeek() {
        guard
            !isInvalidated,
            let request = activeRequest,
            probingRequest != request
        else {
            return
        }

        probingRequest = request
        let requestGeneration = generation
        probe.acquire { [weak self] result in
            self?.finish(
                result,
                request: request,
                generation: requestGeneration
            )
        }
    }

    func cancel() {
        guard !isInvalidated else {
            return
        }

        generation &+= 1
        cancelActiveProbe()
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        generation &+= 1
        cancelActiveProbe()
        panelController = nil
    }

    private func finish(
        _ result: ShippingMediaPeekProbe.Result,
        request: NotchHoverPeekRequest,
        generation expectedGeneration: UInt64
    ) {
        guard
            !isInvalidated,
            generation == expectedGeneration,
            activeRequest == request,
            probingRequest == request
        else {
            return
        }

        activeRequest = nil
        probingRequest = nil

        switch result {
        case .presentation(let presentation):
            presentationModel.applyOneShotPresentation(presentation)

        case .noSession:
            presentationModel.clearAuthoritativePresentation()

        case .failed:
            break
        }
    }

    private func cancelActiveProbe() {
        activeRequest = nil
        probingRequest = nil
        probe.cancel()
    }
}
