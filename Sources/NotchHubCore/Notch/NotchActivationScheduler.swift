import Dispatch
import Foundation

@MainActor
final class MainQueueNotchActivationScheduler: NotchActivationScheduling {
    func schedule(
        after delaySeconds: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any NotchActivationCancellation {
        let workItem = DispatchWorkItem {
            Task { @MainActor in
                action()
            }
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delaySeconds,
            execute: workItem
        )
        return DispatchWorkItemActivationCancellation(workItem: workItem)
    }
}

@MainActor
private final class DispatchWorkItemActivationCancellation: NotchActivationCancellation {
    private let workItem: DispatchWorkItem

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem.cancel()
    }
}
