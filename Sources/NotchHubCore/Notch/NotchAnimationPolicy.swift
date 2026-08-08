import Foundation

struct NotchAnimationPolicy: Equatable, Sendable {
    let duration: TimeInterval

    static let standard = NotchAnimationPolicy(duration: 0.20)
    static let reducedMotion = NotchAnimationPolicy(duration: 0)
}
