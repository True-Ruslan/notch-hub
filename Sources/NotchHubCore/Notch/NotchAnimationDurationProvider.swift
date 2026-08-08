import AppKit
import Foundation

@MainActor
final class NotchAnimationDurationProvider {
    static let standardDuration: TimeInterval = 0.20

    private let notificationCenter: NotificationCenter
    private let readReduceMotion: @MainActor () -> Bool
    private var observer: NSObjectProtocol?
    private var isInvalidated = false

    private(set) var currentDuration: TimeInterval
    var onDurationChange: (@MainActor (TimeInterval) -> Void)?

    init(
        notificationCenter: NotificationCenter,
        readReduceMotion: @escaping @MainActor () -> Bool
    ) {
        self.notificationCenter = notificationCenter
        self.readReduceMotion = readReduceMotion
        self.currentDuration = readReduceMotion() ? 0 : Self.standardDuration
        self.observer = notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
    }

    static func live() -> NotchAnimationDurationProvider {
        let workspace = NSWorkspace.shared
        return NotchAnimationDurationProvider(
            notificationCenter: workspace.notificationCenter,
            readReduceMotion: {
                workspace.accessibilityDisplayShouldReduceMotion
            }
        )
    }

    func invalidate() {
        guard !isInvalidated else {
            return
        }

        isInvalidated = true
        if let observer {
            notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        onDurationChange = nil
    }

    private func refresh() {
        guard !isInvalidated else {
            return
        }

        let duration = readReduceMotion() ? 0 : Self.standardDuration
        guard duration != currentDuration else {
            return
        }

        currentDuration = duration
        onDurationChange?(duration)
    }
}
