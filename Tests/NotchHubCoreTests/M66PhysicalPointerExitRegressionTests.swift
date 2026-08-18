import CoreGraphics
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct M66PhysicalPointerExitRegressionTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        peekFrame: CGRect(x: 320, y: 804, width: 360, height: 96),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func expandedPointerOutsideRetentionRegionTargetsCompact() {
        let result = NotchPointerPolicy.presentation(
            current: .expanded,
            pointer: CGPoint(x: 100, y: 500),
            layout: layout
        )

        #expect(result == .compact)
    }

    @Test
    func expandedPointerExitRestoresAcceptedNonHapticCollapseIntent() {
        let recorder = PointerExitIntentRecorder()
        let coordinator = NotchInteractionCoordinator(
            scheduleActivation: { _, _ in {} },
            emitIntent: { intent in
                recorder.intents.append(intent)
            }
        )

        coordinator.pointerMoved(
            to: CGPoint(x: 100, y: 500),
            layout: layout,
            currentPresentation: .expanded
        )

        #expect(recorder.intents.count == 1)
        #expect(recorder.intents.first?.isPointerExitCollapse == true)
    }

    @Test
    func pointerExitRetargetsOwnedInteractiveCollapseToStableCompact() {
        let fixture = makeTransitionFixture(initialPresentation: .expanded)

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .expanded,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.endpoint.frames == [layout.compactFrame])
        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func pointerExitCancelsOwnedInteractiveExpansionBackToCompact() {
        let fixture = makeTransitionFixture(initialPresentation: .compact)

        #expect(
            fixture.coordinator.beginInteractiveTransition(
                from: .compact,
                layout: layout
            )
        )
        fixture.coordinator.updateInteractiveTransition(
            verticalDistance: 109,
            layout: layout
        )

        fixture.coordinator.accept(.pointerExitCollapse, layout: layout)

        #expect(fixture.endpoint.frames == [layout.compactFrame])
        #expect(fixture.coordinator.phase.isCollapsing)
        #expect(fixture.coordinator.desiredPresentation == .compact)
        #expect(fixture.model.contentPresentation == .expanded)
        #expect(fixture.haptics.requestCount == 0)
    }

    @Test
    func localScrollPathSettlesWhenInteractiveFrameMovesOutFromUnderPointer() throws {
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )
        let gestureSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaGestureSession.swift"
        )

        #expect(controllerSource.contains("pointer: CGPoint"))
        #expect(
            controllerSource.contains(
                "NotchPointerPolicy.containsInteractivePointer(pointer, in: panel.frame)"
            )
        )
        #expect(!controllerSource.contains("panel.frame.contains(pointer)"))
        #expect(controllerSource.contains("collapseInteractiveTransitionIfPointerExited(pointer)"))
        #expect(controllerSource.contains("transitionCoordinator.accept(.pointerExitCollapse"))
        #expect(gestureSource.contains("pointer: NSEvent.mouseLocation"))
        #expect(!gestureSource.contains("addGlobalMonitorForEvents(matching: .scrollWheel"))
    }

    private func makeTransitionFixture(
        initialPresentation: NotchPresentation
    ) -> PointerExitTransitionFixture {
        let model = NotchPanelModel()
        model.setContentPresentation(initialPresentation)
        let endpoint = PointerExitEndpointRecorder()
        let interactive = PointerExitInteractiveRecorder()
        let haptics = PointerExitHapticRecorder()
        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: initialPresentation,
            animationDuration: { 0.20 },
            animate: { frame, _, _, _ in
                endpoint.frames.append(frame)
            },
            cancelAnimation: {},
            performExpansionHaptic: {
                haptics.requestCount += 1
            },
            applyInteractivePresentation: { frame, _ in
                interactive.frames.append(frame)
            }
        )

        return PointerExitTransitionFixture(
            model: model,
            endpoint: endpoint,
            interactive: interactive,
            haptics: haptics,
            coordinator: coordinator
        )
    }

    private func sourceText(relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot =
            testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

private extension NotchInteractionIntent {
    var isPointerExitCollapse: Bool {
        if case .pointerExitCollapse = self {
            true
        } else {
            false
        }
    }
}

private extension NotchPanelTransitionPhase {
    var isCollapsing: Bool {
        if case .collapsing = self {
            true
        } else {
            false
        }
    }
}

@MainActor
private final class PointerExitIntentRecorder {
    var intents: [NotchInteractionIntent] = []
}

@MainActor
private final class PointerExitEndpointRecorder {
    var frames: [CGRect] = []
}

@MainActor
private final class PointerExitInteractiveRecorder {
    var frames: [CGRect] = []
}

@MainActor
private final class PointerExitHapticRecorder {
    var requestCount = 0
}

@MainActor
private struct PointerExitTransitionFixture {
    let model: NotchPanelModel
    let endpoint: PointerExitEndpointRecorder
    let interactive: PointerExitInteractiveRecorder
    let haptics: PointerExitHapticRecorder
    let coordinator: NotchPanelTransitionCoordinator
}
