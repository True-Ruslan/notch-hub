import SwiftUI

@MainActor
public final class NotchPanelLayoutModel: ObservableObject {
    private(set) var baseLayout: NotchLayout
    private(set) var compactHorizontalExtension: CGFloat

    @Published public private(set) var currentLayout: NotchLayout

    public init(
        baseLayout: NotchLayout,
        compactHorizontalExtension: CGFloat = 0
    ) {
        let boundedExtension = max(0, compactHorizontalExtension)
        self.baseLayout = baseLayout
        self.compactHorizontalExtension = boundedExtension
        self.currentLayout = baseLayout.withCompactHorizontalExtension(boundedExtension)
    }

    @discardableResult
    func updateBaseLayout(_ layout: NotchLayout) -> Bool {
        guard layout != baseLayout else {
            return false
        }

        baseLayout = layout
        currentLayout = effectiveLayout(replacingBaseLayout: layout)
        return true
    }

    @discardableResult
    func setCompactHorizontalExtension(_ extensionWidth: CGFloat) -> Bool {
        let boundedExtension = max(0, extensionWidth)
        guard boundedExtension != compactHorizontalExtension else {
            return false
        }

        compactHorizontalExtension = boundedExtension
        currentLayout = effectiveLayout(replacingBaseLayout: baseLayout)
        return true
    }

    func effectiveLayout(replacingBaseLayout layout: NotchLayout) -> NotchLayout {
        layout.withCompactHorizontalExtension(compactHorizontalExtension)
    }
}
