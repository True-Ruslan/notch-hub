import Foundation

enum NotchAnimationTiming: Equatable, Sendable {
    case easeInOut
}

struct NotchAnimationPolicy: Equatable, Sendable {
    let duration: TimeInterval
    let timing: NotchAnimationTiming

    static let standard = NotchAnimationPolicy(
        duration: 0.20,
        timing: .easeInOut
    )

    static let reducedMotion = NotchAnimationPolicy(
        duration: 0,
        timing: .easeInOut
    )
}

@MainActor
protocol NotchAnimationPolicyProviding: AnyObject {
    var currentPolicy: NotchAnimationPolicy { get }
}
