import Testing

@testable import NotchHubCore

struct EffectiveReduceMotionTests {
    @Test
    func systemOverrideFollowsTheLiveSystemValue() {
        #expect(effectiveReduceMotion(systemValue: true, override: .system) == true)
        #expect(effectiveReduceMotion(systemValue: false, override: .system) == false)
    }

    @Test
    func alwaysOnIgnoresTheSystemValue() {
        #expect(effectiveReduceMotion(systemValue: true, override: .alwaysOn) == true)
        #expect(effectiveReduceMotion(systemValue: false, override: .alwaysOn) == true)
    }

    @Test
    func alwaysOffIgnoresTheSystemValue() {
        #expect(effectiveReduceMotion(systemValue: true, override: .alwaysOff) == false)
        #expect(effectiveReduceMotion(systemValue: false, override: .alwaysOff) == false)
    }
}
