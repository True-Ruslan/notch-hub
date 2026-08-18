#if NOTCHHUB_UI_TESTING
    import SwiftUI

    @MainActor
    struct UITestHapticDiagnosticsView<Content: View>: View {
        @ObservedObject private var recorder: UITestHapticRecorder
        private let content: Content

        init(
            recorder: UITestHapticRecorder,
            @ViewBuilder content: () -> Content
        ) {
            self.recorder = recorder
            self.content = content()
        }

        var body: some View {
            content
                .overlay(alignment: .topLeading) {
                    Text("\(recorder.expansionCount)")
                        .font(.system(size: 1))
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                        .accessibilityLabel("UI test haptic count")
                        .accessibilityIdentifier(UITestHapticRecorder.accessibilityIdentifier)
                        .accessibilityValue("\(recorder.expansionCount)")
                }
        }
    }
#endif
