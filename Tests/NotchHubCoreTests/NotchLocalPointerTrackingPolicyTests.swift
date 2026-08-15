import Foundation
import Testing

struct NotchLocalPointerTrackingPolicyTests {
    @Test
    func hostingViewUsesActiveAlwaysVisibleTrackingForHoverEntryMoveAndExit() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift"
        )

        #expect(source.contains("NSTrackingArea"))
        #expect(source.contains(".mouseEnteredAndExited"))
        #expect(source.contains(".mouseMoved"))
        #expect(source.contains(".activeAlways"))
        #expect(source.contains(".inVisibleRect"))
        #expect(source.contains("override func updateTrackingAreas()"))
        #expect(source.contains("override func mouseEntered(with event: NSEvent)"))
        #expect(source.contains("override func mouseMoved(with event: NSEvent)"))
        #expect(source.contains("override func mouseExited(with event: NSEvent)"))
        #expect(source.contains("NSEvent.mouseLocation"))
        #expect(!source.contains("Timer.scheduledTimer"))
        #expect(!source.contains("CVDisplayLink"))
        #expect(!source.contains("CGEvent.tapCreate"))
    }

    @Test
    func localMouseDownCancelsPendingHoverBeforeSwiftUITapDispatch() throws {
        let hostingSource = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchHostingViewFactory.swift"
        )
        let controllerSource = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(hostingSource.contains("onNotchMouseDown"))
        #expect(hostingSource.contains("override func mouseDown(with event: NSEvent)"))
        #expect(hostingSource.contains("onNotchMouseDown?()"))
        #expect(hostingSource.contains("super.mouseDown(with: event)"))
        #expect(controllerSource.contains("trackingView.onNotchMouseDown"))
        #expect(controllerSource.contains("cancelPendingActivationForInteractiveTransition()"))
    }

    @Test
    func panelControllerBindsLocalTrackingToExistingInteractionPath() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(source.contains("NotchLocalPointerTracking"))
        #expect(source.contains("onNotchPointerEvent"))
        #expect(source.contains("updateInteraction(for: pointer)"))
        #expect(source.contains("pointerMonitor.start"))
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
