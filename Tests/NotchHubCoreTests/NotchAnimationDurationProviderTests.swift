import AppKit
import Foundation
import Testing
@testable import NotchHubCore

@MainActor
struct NotchAnimationDurationProviderTests {
    @Test
    func startsWithStandardDurationWhenReduceMotionIsDisabled() {
        let source = MutableReduceMotionSource(isEnabled: false)
        let provider = NotchAnimationDurationProvider(
            notificationCenter: NotificationCenter(),
            readReduceMotion: { source.isEnabled }
        )

        #expect(provider.currentDuration == 0.20)
    }

    @Test
    func startsWithZeroDurationWhenReduceMotionIsEnabled() {
        let source = MutableReduceMotionSource(isEnabled: true)
        let provider = NotchAnimationDurationProvider(
            notificationCenter: NotificationCenter(),
            readReduceMotion: { source.isEnabled }
        )

        #expect(provider.currentDuration == 0)
    }

    @Test
    func accessibilityNotificationPublishesOnlyActualDurationChanges() {
        let notificationCenter = NotificationCenter()
        let source = MutableReduceMotionSource(isEnabled: false)
        let provider = NotchAnimationDurationProvider(
            notificationCenter: notificationCenter,
            readReduceMotion: { source.isEnabled }
        )
        var changes: [TimeInterval] = []
        provider.onDurationChange = { changes.append($0) }

        notificationCenter.post(
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        #expect(changes.isEmpty)

        source.isEnabled = true
        notificationCenter.post(
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        #expect(provider.currentDuration == 0)
        #expect(changes == [0])

        notificationCenter.post(
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        #expect(changes == [0])

        source.isEnabled = false
        notificationCenter.post(
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        #expect(provider.currentDuration == 0.20)
        #expect(changes == [0, 0.20])
    }

    @Test
    func invalidationIsIdempotentAndStopsAccessibilityUpdates() {
        let notificationCenter = NotificationCenter()
        let source = MutableReduceMotionSource(isEnabled: false)
        let provider = NotchAnimationDurationProvider(
            notificationCenter: notificationCenter,
            readReduceMotion: { source.isEnabled }
        )
        var changes: [TimeInterval] = []
        provider.onDurationChange = { changes.append($0) }

        provider.invalidate()
        provider.invalidate()
        source.isEnabled = true
        notificationCenter.post(
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )

        #expect(provider.currentDuration == 0.20)
        #expect(changes.isEmpty)
    }
}

@MainActor
private final class MutableReduceMotionSource {
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}
