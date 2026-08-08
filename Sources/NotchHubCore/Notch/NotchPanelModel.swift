import SwiftUI

public enum NotchPresentation: Equatable, Sendable {
    case compact
    case expanded
}

@MainActor
public final class NotchPanelModel: ObservableObject {
    @Published public private(set) var contentPresentation: NotchPresentation = .compact

    public init() {}

    public func setContentPresentation(_ presentation: NotchPresentation) {
        contentPresentation = presentation
    }
}
