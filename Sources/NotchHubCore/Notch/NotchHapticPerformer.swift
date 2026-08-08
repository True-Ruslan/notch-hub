import AppKit

@MainActor
final class AppKitNotchHapticPerformer {
    func performExpansionHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
    }
}
