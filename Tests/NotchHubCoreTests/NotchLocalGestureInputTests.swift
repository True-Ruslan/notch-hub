import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import NotchHubCore

@MainActor
struct NotchLocalGestureInputTests {
    private let layout = NotchLayout(
        hasHardwareNotch: true,
        hardwareNotchWidth: 180,
        compactFrame: CGRect(x: 410, y: 868, width: 180, height: 32),
        expandedFrame: CGRect(x: 240, y: 650, width: 520, height: 250)
    )

    @Test
    func hostingFactoryOwnsLocalScrollDeliveryWithoutEventMonitors() throws {
        let view = NotchHostingViewFactory.make(
            rootView: Text("Local gesture input"),
            onScrollWheel: { _ in }
        )

        #expect(view.sizingOptions == [.minSize, .maxSize])

        let source = try repositorySource(
            "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift"
        )
        #expect(source.contains("override func scrollWheel(with event: NSEvent)"))
        #expect(!source.contains("addGlobalMonitorForEvents(matching: .scrollWheel"))
        #expect(!source.contains("addLocalMonitorForEvents(matching: .scrollWheel"))
    }

    @Test
    func programmaticCollapseIsSymmetricNonHapticAndRejectsStaleCompletion() {
        let model = NotchPanelModel()
        model.setContentPresentation(.expanded)
        var hapticCount = 0
        var requests: [AnimationRequest] = []
        var completions: [@MainActor () -> Void] = []

        let coordinator = NotchPanelTransitionCoordinator(
            model: model,
            initialPresentation: .expanded,
            animationDuration: { 0.20 },
            animate: { frame, cornerRadius, duration, completion in
                requests.append(
                    AnimationRequest(
                        frame: frame,
                        cornerRadius: cornerRadius,
                        duration: duration
                    )
                )
                completions.append(completion)
            },
            cancelAnimation: {},
            performExpansionHaptic: { hapticCount += 1 }
        )

        coordinator.requestProgrammaticCollapse(layout: layout)
        coordinator.requestProgrammaticCollapse(layout: layout)

        #expect(requests.count == 1)
        #expect(requests[0].frame == layout.compactFrame)
        #expect(requests[0].cornerRadius == 12)
        #expect(requests[0].duration == 0.20)
        #expect(hapticCount == 0)
        #expect(coordinator.desiredPresentation == .compact)
        #expect(model.contentPresentation == .expanded)

        coordinator.requestProgrammaticExpansion(layout: layout)

        #expect(requests.count == 2)
        #expect(requests[1].frame == layout.expandedFrame)
        #expect(hapticCount == 0)

        completions[0]()
        #expect(coordinator.desiredPresentation == .expanded)
        #expect(model.contentPresentation == .expanded)

        completions[1]()
        #expect(coordinator.desiredPresentation == .expanded)
        #expect(model.contentPresentation == .expanded)
    }

    @Test
    func panelControllerExposesOnlyTransitionOwnedProgrammaticIntents() throws {
        let source = try repositorySource(
            "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(source.contains("public func requestExpansion()"))
        #expect(source.contains("public func requestCollapse()"))
        #expect(
            source.contains(
                "transitionCoordinator.requestProgrammaticExpansion(layout: layoutState.currentLayout)"
            )
        )
        #expect(
            source.contains(
                "transitionCoordinator.requestProgrammaticCollapse(layout: layoutState.currentLayout)"
            )
        )
        #expect(!source.contains("panel.setFrame("))
    }

    private func repositorySource(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

private struct AnimationRequest: Equatable {
    let frame: CGRect
    let cornerRadius: CGFloat
    let duration: TimeInterval
}
