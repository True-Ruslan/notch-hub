import AppKit
import QuartzCore

let notchCornerAnimationKey = "NotchHub.cornerRadius"

@MainActor
func animateNotchPanel(
    panel: NSPanel,
    chromeView: NSView,
    frame: CGRect,
    cornerRadius: CGFloat,
    duration: TimeInterval,
    completion: @escaping @MainActor () -> Void
) {
    chromeView.wantsLayer = true
    guard let layer = chromeView.layer else {
        panel.setFrame(frame, display: true)
        completion()
        return
    }

    layer.masksToBounds = true
    layer.cornerCurve = .continuous

    if duration <= 0 {
        layer.removeAnimation(forKey: notchCornerAnimationKey)
        setNotchCornerRadius(cornerRadius, on: layer)
        panel.setFrame(frame, display: true)
        completion()
        return
    }

    let visibleCornerRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
    layer.removeAnimation(forKey: notchCornerAnimationKey)
    setNotchCornerRadius(cornerRadius, on: layer)

    let cornerAnimation = CABasicAnimation(keyPath: "cornerRadius")
    cornerAnimation.fromValue = visibleCornerRadius
    cornerAnimation.toValue = cornerRadius
    cornerAnimation.duration = duration
    cornerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    layer.add(cornerAnimation, forKey: notchCornerAnimationKey)

    NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().setFrame(frame, display: true)
    } completionHandler: {
        MainActor.assumeIsolated {
            completion()
        }
    }
}

@MainActor
func applyInteractiveNotchPanelPresentation(
    panel: NSPanel,
    chromeView: NSView,
    frame: CGRect,
    cornerRadius: CGFloat
) {
    chromeView.wantsLayer = true
    if let layer = chromeView.layer {
        layer.masksToBounds = true
        layer.cornerCurve = .continuous
        layer.removeAnimation(forKey: notchCornerAnimationKey)
        setNotchCornerRadius(cornerRadius, on: layer)
    }
    panel.setFrame(frame, display: true)
}

@MainActor
func cancelNotchPanelAnimation(chromeView: NSView) {
    freezeVisibleCornerRadius(chromeView: chromeView)
}

@MainActor
private func freezeVisibleCornerRadius(chromeView: NSView) {
    guard let layer = chromeView.layer else {
        return
    }

    let visibleCornerRadius = layer.presentation()?.cornerRadius ?? layer.cornerRadius
    layer.removeAnimation(forKey: notchCornerAnimationKey)
    setNotchCornerRadius(visibleCornerRadius, on: layer)
}

@MainActor
private func setNotchCornerRadius(_ cornerRadius: CGFloat, on layer: CALayer) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.cornerRadius = cornerRadius
    CATransaction.commit()
}
