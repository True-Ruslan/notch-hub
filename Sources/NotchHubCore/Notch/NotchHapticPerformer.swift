import AppKit

@MainActor
final class AppKitNotchHapticPerformer: NotchHapticPerforming {
    func performExpansionHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .now
        )
    }
}
