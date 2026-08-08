import AppKit
import QuartzCore

@MainActor
final class AppKitNotchPanelAnimationDriver {
    static let cornerAnimationKey = "NotchHub.cornerRadius"

    private weak var panel: NSPanel?
    private weak var chromeView: NSView?
    private var generation: UInt64 = 0

    init(panel: NSPanel, chromeView: NSView) {
        self.panel = panel
        self.chromeView = chromeView
    }

    func animate(
        frame: CGRect,
        cornerRadius: CGFloat,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        generation &+= 1
        let scheduledGeneration = generation

        guard let panel, let chromeView else {
            completion()
            return
        }

        chromeView.wantsLayer = true
        guard let layer = chromeView.layer else {
            panel.setFrame(frame, display: true)
            completion()
            return
        }

        layer.masksToBounds = true
        layer.cornerCurve = .continuous

        if duration <= 0 {
            layer.removeAnimation(forKey: Self.cornerAnimationKey)
            setCornerRadius(cornerRadius, on: layer)
            panel.setFrame(frame, display: true)
            completeIfCurrent(
                generation: scheduledGeneration,
                completion: completion
            )
            return
        }

        let visibleCornerRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
        layer.removeAnimation(forKey: Self.cornerAnimationKey)
        setCornerRadius(cornerRadius, on: layer)

        let cornerAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerAnimation.fromValue = visibleCornerRadius
        cornerAnimation.toValue = cornerRadius
        cornerAnimation.duration = duration
        cornerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(cornerAnimation, forKey: Self.cornerAnimationKey)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.completeIfCurrent(
                    generation: scheduledGeneration,
                    completion: completion
                )
            }
        }
    }

    func cancel() {
        generation &+= 1
        freezeVisibleCornerRadius()
    }

    private func freezeVisibleCornerRadius() {
        guard let layer = chromeView?.layer else {
            return
        }

        let visibleCornerRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
        layer.removeAnimation(forKey: Self.cornerAnimationKey)
        setCornerRadius(visibleCornerRadius, on: layer)
    }

    private func setCornerRadius(_ cornerRadius: CGFloat, on layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.cornerRadius = cornerRadius
        CATransaction.commit()
    }

    private func completeIfCurrent(
        generation scheduledGeneration: UInt64,
        completion: @escaping @MainActor () -> Void
    ) {
        guard generation == scheduledGeneration else {
            return
        }
        completion()
    }
}
