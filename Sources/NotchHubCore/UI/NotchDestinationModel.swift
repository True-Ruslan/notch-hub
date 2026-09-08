import Combine

public enum NotchDestination: Equatable, Sendable {
    case home
    case shelf
}

@MainActor
public final class NotchDestinationModel: ObservableObject {
    @Published public private(set) var destination: NotchDestination

    public init(destination: NotchDestination = .home) {
        self.destination = destination
    }

    public func select(_ destination: NotchDestination) {
        self.destination = destination
    }

    public func reset() {
        destination = .home
    }
}
