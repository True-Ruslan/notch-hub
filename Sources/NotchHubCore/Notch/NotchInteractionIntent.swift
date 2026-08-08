enum NotchInteractionCause: Equatable, Sendable {
    case deliberateHover
    case pointerExit
    case programmatic
}

struct NotchInteractionIntent: Equatable, Sendable {
    let desiredPresentation: NotchPresentation
    let cause: NotchInteractionCause
    let hapticEligible: Bool
}
