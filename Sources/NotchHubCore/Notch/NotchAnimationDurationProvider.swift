import Foundation

public let notchStandardAnimationDuration: TimeInterval = 0.20

public func notchAnimationDuration(reduceMotion: Bool) -> TimeInterval {
    reduceMotion ? 0 : notchStandardAnimationDuration
}
