import SwiftUI

public enum NotchPresentation: Equatable, Sendable {
    case compact
    case expanded
}

@MainActor
public final class NotchPanelModel: ObservableObject {
    @Published public private(set) var presentation: NotchPresentation = .compact

    public init() {}

    public func setHovered(_ isHovered: Bool) {
        presentation = isHovered ? .expanded : .compact
    }

    public func toggle() {
        presentation = presentation == .compact ? .expanded : .compact
    }
}
