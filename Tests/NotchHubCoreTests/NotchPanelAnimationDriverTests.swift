import AppKit
import CoreGraphics
import QuartzCore
import Testing
@testable import NotchHubCore

@MainActor
struct NotchPanelAnimationDriverTests {
    @Test
    func zeroDurationAppliesExactEndpointAndCompletesSynchronouslyOnce() {
        let fixture = makeFixture()
        let target = CGRect(x: 240, y: 650, width: 520, height: 250)
        var completionCount = 0

        fixture.driver.animate(
            frame: target,
            cornerRadius: 22,
            duration: 0,
            completion: { completionCount += 1 }
        )

        #expect(fixture.panel.frame == target)
        #expect(fixture.chromeView.layer?.cornerRadius == 22)
        #expect(fixture.chromeView.layer?.animation(forKey: AppKitNotchPanelAnimationDriver.cornerAnimationKey) == nil)
        #expect(completionCount == 1)
    }

    @Test
    func animatedRequestInstallsSystemCornerAnimationAndTargetModelValues() {
        let fixture = makeFixture()
        let target = CGRect(x: 240, y: 650, width: 520, height: 250)
        var completionCount = 0

        fixture.driver.animate(
            frame: target,
            cornerRadius: 22,
            duration: 0.20,
            completion: { completionCount += 1 }
        )

        let animation = fixture.chromeView.layer?.animation(
            forKey: AppKitNotchPanelAnimationDriver.cornerAnimationKey
        ) as? CABasicAnimation

        #expect(fixture.panel.frame == target)
        #expect(fixture.chromeView.layer?.cornerRadius == 22)
        #expect(animation?.keyPath == "cornerRadius")
        #expect(animation?.toValue as? CGFloat == 22)
        #expect(animation?.duration == 0.20)
        #expect(completionCount == 0)

        fixture.driver.cancel()
        #expect(fixture.chromeView.layer?.animation(forKey: AppKitNotchPanelAnimationDriver.cornerAnimationKey) == nil)
    }

    @Test
    func thirtyTwoImmediateCyclesPreserveAppKitChromeAndExactFrames() {
        let fixture = makeFixture()
        let compact = CGRect(x: 410, y: 868, width: 180, height: 32)
        let expanded = CGRect(x: 240, y: 650, width: 520, height: 250)

        for _ in 0..<32 {
            fixture.driver.animate(
                frame: expanded,
                cornerRadius: 22,
                duration: 0,
                completion: {}
            )
            #expect(fixture.panel.frame == expanded)
            #expect(fixture.chromeView.layer?.masksToBounds == true)
            #expect(fixture.chromeView.layer?.cornerCurve == .continuous)
            #expect(fixture.chromeView.layer?.cornerRadius == 22)

            fixture.driver.animate(
                frame: compact,
                cornerRadius: 12,
                duration: 0,
                completion: {}
            )
            #expect(fixture.panel.frame == compact)
            #expect(fixture.chromeView.layer?.masksToBounds == true)
            #expect(fixture.chromeView.layer?.cornerCurve == .continuous)
            #expect(fixture.chromeView.layer?.cornerRadius == 12)
        }
    }

    private func makeFixture() -> DriverFixture {
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

        return DriverFixture(
            panel: panel,
            chromeView: chromeView,
            driver: AppKitNotchPanelAnimationDriver(
                panel: panel,
                chromeView: chromeView
            )
        )
    }
}

@MainActor
private struct DriverFixture {
    let panel: NSPanel
    let chromeView: NSView
    let driver: AppKitNotchPanelAnimationDriver
}
