import AppKit
import Testing

@testable import NotchHubCore

@MainActor
struct NotchPanelSpacesFullscreenPolicyTests {
    @Test
    func panelJoinsAllSpacesAndRemainsAuxiliaryOverFullscreenApps() {
        let controller = NotchPanelController()

        #expect(
            controller.panel.collectionBehavior == [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        )
    }

    @Test
    func panelStaysAtStatusBarLevelAndNeverHidesOnDeactivate() {
        let controller = NotchPanelController()

        #expect(controller.panel.level == .statusBar)
        #expect(controller.panel.hidesOnDeactivate == false)
    }

    @Test
    func panelStyleMaskIsBorderlessNonactivatingAndNeverAnOrdinaryActivatableWindow() {
        let controller = NotchPanelController()

        #expect(controller.panel.styleMask.contains(.borderless))
        #expect(controller.panel.styleMask.contains(.nonactivatingPanel))
        #expect(!controller.panel.styleMask.contains(.titled))
        #expect(!controller.panel.styleMask.contains(.closable))
        #expect(!controller.panel.styleMask.contains(.resizable))
    }
}
