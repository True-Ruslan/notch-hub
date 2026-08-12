import AppKit
import CoreGraphics
import QuartzCore
import Testing
@testable import NotchHubCore

@MainActor
struct NotchInteractivePanelAnimationDriverTests {
    @Test
    func interactivePresentationAppliesExactFrameAndCornerSynchronously() {
        let fixture = makeFixture()
        let target = CGRect(x: 325, y: 759, width: 350, height: 141)

        applyInteractiveNotchPanelPresentation(
            panel: fixture.panel,
            chromeView: fixture.chromeView,
            frame: target,
            cornerRadius: 17
        )

        #expect(fixture.panel.frame == target)
        #expect(fixture.chromeView.layer?.cornerRadius == 17)
        #expect(fixture.chromeView.layer?.masksToBounds == true)
        #expect(fixture.chromeView.layer?.cornerCurve == .continuous)
        #expect(fixture.chromeView.layer?.animation(forKey: notchCornerAnimationKey) == nil)
    }

    @Test
    func interactivePresentationRemovesExistingCornerAnimationBeforeApplyingValue() {
        let fixture = makeFixture()
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = 12
        animation.toValue = 22
        animation.duration = 0.20
        fixture.chromeView.layer?.add(animation, forKey: notchCornerAnimationKey)

        applyInteractiveNotchPanelPresentation(
            panel: fixture.panel,
            chromeView: fixture.chromeView,
            frame: CGRect(x: 325, y: 759, width: 350, height: 141),
            cornerRadius: 17
        )

        #expect(fixture.chromeView.layer?.animation(forKey: notchCornerAnimationKey) == nil)
        #expect(fixture.chromeView.layer?.cornerRadius == 17)
    }

    private func makeFixture() -> InteractiveDriverFixture {
        let initial = CGRect(x: 410, y: 868, width: 180, height: 32)
        let panel = NSPanel(
            contentRect: initial,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let chromeView = NSView(frame: CGRect(origin: .zero, size: initial.size))
        chromeView.wantsLayer = true
        chromeView.layer?.masksToBounds = true
        chromeView.layer?.cornerCurve = .continuous
        chromeView.layer?.cornerRadius = 12
        chromeView.autoresizingMask = [.width, .height]
        panel.contentView = chromeView

        return InteractiveDriverFixture(panel: panel, chromeView: chromeView)
    }
}

@MainActor
private struct InteractiveDriverFixture {
    let panel: NSPanel
    let chromeView: NSView
}
