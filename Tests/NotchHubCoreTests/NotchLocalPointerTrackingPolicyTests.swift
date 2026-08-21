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
    func explicitExpansionTapLivesAboveCompactPeekPresentationSwitches() throws {
        let shellSource = try sourceText(
            relativePath: "Sources/NotchHubCore/UI/NotchRootView.swift"
        )
        let mediaSource = try sourceText(
            relativePath: "Sources/NotchHubApp/MediaNotchRootView.swift"
        )

        #expect(shellSource.contains("private func requestExplicitExpansionFromTap()"))
        #expect(shellSource.contains(".onTapGesture(perform: requestExplicitExpansionFromTap)"))
        #expect(mediaSource.contains("private func requestExplicitExpansionFromTap()"))
        #expect(mediaSource.contains(".onTapGesture(perform: requestExplicitExpansionFromTap)"))
        #expect(shellSource.components(separatedBy: ".onTapGesture").count - 1 == 1)
        #expect(mediaSource.components(separatedBy: ".onTapGesture").count - 1 == 1)
    }

    @Test
    func panelControllerRoutesTrackingEventsThroughBoundedEscapeMonitor() throws {
        let source = try sourceText(
            relativePath: "Sources/NotchHubCore/Notch/NotchPanelController.swift"
        )

        #expect(source.contains("NotchLocalPointerTracking"))
        #expect(source.contains("onNotchPointerEvent"))
        #expect(source.contains("pointerMonitor.handleTrackedPointer(pointer)"))
        #expect(source.contains("pointerMonitor.start"))
        #expect(source.contains("shouldRetainGlobalMonitoring"))
        #expect(source.contains("NotchPointerPolicy.presentation"))
        #expect(source.contains("transitionCoordinator.desiredPresentation"))
        #expect(!source.contains("leftMouseDown"))
        #expect(!source.contains("addLocalMonitorForEvents"))
        #expect(!source.contains("CGEvent.tapCreate"))
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
