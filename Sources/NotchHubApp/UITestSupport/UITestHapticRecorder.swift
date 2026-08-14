#if NOTCHHUB_UI_TESTING
    import Combine

    @MainActor
    final class UITestHapticRecorder: ObservableObject {
        static let accessibilityIdentifier = "ui-test.hapticCount"

        @Published private(set) var expansionCount = 0

        func performExpansionHaptic() {
            expansionCount += 1
        }
    }
#endif
