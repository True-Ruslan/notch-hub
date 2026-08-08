import Testing
@testable import NotchHubCore

struct NotchAnimationDurationProviderTests {
    @Test
    func standardMotionUsesTwoTenthsDuration() {
        #expect(notchAnimationDuration(reduceMotion: false) == 0.20)
    }

    @Test
    func reduceMotionUsesImmediateDuration() {
        #expect(notchAnimationDuration(reduceMotion: true) == 0)
    }
}
