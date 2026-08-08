import Foundation

let notchStandardAnimationDuration: TimeInterval = 0.20

func notchAnimationDuration(reduceMotion: Bool) -> TimeInterval {
    reduceMotion ? 0 : notchStandardAnimationDuration
}
