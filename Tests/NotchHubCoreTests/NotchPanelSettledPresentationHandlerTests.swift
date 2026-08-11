import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelSettledPresentationHandlerTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func settledPresentationHandlerFiresOnlyAfterMatchingCompletion() {
        let model = NotchPanelModel()
        let driver = SettledPresentationManualDriver()
        let recorder = SettledPresentationRecorder()
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            animationDuration: { 0.20 },
            animate: { frame, cornerRadius, duration, completion in
                driver.animate(
                    frame: frame,
                    cornerRadius: cornerRadius,
                    duration: duration,
                    completion: completion
                )
            },
            cancelAnimation: { driver.cancel() },
            performExpansionHaptic: {}
        )
        coordinator.settledPresentationHandler = { presentation in
            recorder.presentations.append(presentation)
        }

        coordinator.accept(.deliberateExpansion, layout: layout)
        #expect(recorder.presentations.isEmpty)

        coordinator.accept(.pointerExitCollapse, layout: layout)
        #expect(recorder.presentations.isEmpty)

        driver.complete(index: 0)
        #expect(recorder.presentations.isEmpty)

        driver.complete(index: 1)
        #expect(recorder.presentations == [.compact])

        coordinator.accept(.deliberateExpansion, layout: layout)
        #expect(recorder.presentations == [.compact])

        driver.complete(index: 2)
        #expect(recorder.presentations == [.compact, .expanded])
    }
}

@MainActor
private final class SettledPresentationRecorder {
    var presentations: [NotchPresentation] = []
}

@MainActor
private final class SettledPresentationManualDriver {
    struct Request {
        let completion: @MainActor () -> Void
    }

    private(set) var requests: [Request] = []

    func animate(
        frame _: CGRect,
        cornerRadius _: CGFloat,
        duration _: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        requests.append(Request(completion: completion))
    }

    func cancel() {}

    func complete(index: Int) {
        requests[index].completion()
    }
}
