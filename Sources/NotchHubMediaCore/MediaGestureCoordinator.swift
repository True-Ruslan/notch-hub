public enum MediaGestureSurface: Sendable, Equatable {
    case compact
    case expanded
}

public enum MediaGesturePhase: Sendable, Equatable {
    case began
    case changed
    case ended
    case cancelled
}

public enum MediaGestureDirection: Sendable, Equatable {
    case previous
    case next
}

public struct MediaGestureSample: Sendable, Equatable {
    public let phase: MediaGesturePhase
    public let deltaX: Double
    public let deltaY: Double
    public let interactiveWidth: Double
    public let isMomentum: Bool

    public init(
        phase: MediaGesturePhase,
        deltaX: Double,
        deltaY: Double,
        interactiveWidth: Double,
        isMomentum: Bool
    ) {
        self.phase = phase
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.interactiveWidth = interactiveWidth
        self.isMomentum = isMomentum
    }
}

public enum MediaGestureCapability: Sendable, Equatable {
    case pending
    case supported
    case unavailable
}

public enum MediaGestureEffect: Sendable, Equatable {
    case requestCompactCapability(gestureID: UInt64, direction: MediaGestureDirection)
    case requestArmHaptic
    case commit(MediaGestureDirection)
    case requestExpansion
    case requestCollapse
    case visualOffset(Double)
    case resetVisualOffset
}

@MainActor
public final class MediaGestureCoordinator {
    private static let horizontalThresholdRatio = 0.28
    private static let minimumHorizontalThreshold = 70.0
    private static let maximumHorizontalThreshold = 120.0
    private static let horizontalDisarmHysteresis = 20.0
    private static let verticalCommitThreshold = 70.0
    private static let axisDominanceRatio = 1.25
    private static let thresholdComparisonTolerance = 1e-9

    private enum CapturedAxis: Equatable {
        case undecided
        case horizontal(MediaGestureDirection)
        case vertical
    }

    private struct ActiveGesture {
        let id: UInt64
        let surface: MediaGestureSurface
        let horizontalThreshold: Double
        var cumulativeX = 0.0
        var cumulativeY = 0.0
        var capturedAxis: CapturedAxis = .undecided
        var isArmed = false
        var compactCapability: MediaGestureCapability = .pending
        var requestedCompactCapability = false
        var hasHorizontalVisualOffset = false
    }

    private var nextGestureID: UInt64 = 0
    private var activeGesture: ActiveGesture?

    public init() {}

    public func handle(
        _ sample: MediaGestureSample,
        surface: MediaGestureSurface,
        previous: MediaGestureCapability,
        next: MediaGestureCapability,
        seekActive: Bool
    ) -> [MediaGestureEffect] {
        if seekActive {
            return cancelActiveGestureIfNeeded()
        }

        guard !sample.isMomentum else {
            return []
        }

        switch sample.phase {
        case .began:
            return beginGesture(sample: sample, surface: surface)
        case .changed:
            return changeGesture(sample: sample, previous: previous, next: next)
        case .ended:
            return endGesture()
        case .cancelled:
            return cancelActiveGestureIfNeeded()
        }
    }

    public func resolveCompactCapability(
        gestureID: UInt64,
        direction: MediaGestureDirection,
        supported: Bool
    ) -> [MediaGestureEffect] {
        guard
            var gesture = activeGesture,
            gesture.id == gestureID,
            gesture.surface == .compact,
            gesture.capturedAxis == .horizontal(direction),
            gesture.requestedCompactCapability,
            gesture.compactCapability == .pending
        else {
            return []
        }

        gesture.compactCapability = supported ? .supported : .unavailable
        var effects: [MediaGestureEffect] = []
        if supported, !gesture.isArmed,
            Self.reachedThreshold(
                directionalDistance(for: gesture, direction: direction),
                threshold: gesture.horizontalThreshold
            )
        {
            gesture.isArmed = true
            effects.append(.requestArmHaptic)
        }
        activeGesture = gesture
        return effects
    }

    public func invalidate() -> [MediaGestureEffect] {
        nextGestureID &+= 1
        return cancelActiveGestureIfNeeded()
    }

    private func beginGesture(
        sample: MediaGestureSample,
        surface: MediaGestureSurface
    ) -> [MediaGestureEffect] {
        let reset = cancelActiveGestureIfNeeded()
        nextGestureID &+= 1
        activeGesture = ActiveGesture(
            id: nextGestureID,
            surface: surface,
            horizontalThreshold: Self.horizontalThreshold(for: sample.interactiveWidth)
        )
        return reset
    }

    private func changeGesture(
        sample: MediaGestureSample,
        previous: MediaGestureCapability,
        next: MediaGestureCapability
    ) -> [MediaGestureEffect] {
        guard var gesture = activeGesture else {
            return []
        }

        gesture.cumulativeX += sample.deltaX
        gesture.cumulativeY += sample.deltaY

        if gesture.capturedAxis == .undecided {
            gesture.capturedAxis = captureAxis(
                cumulativeX: gesture.cumulativeX,
                cumulativeY: gesture.cumulativeY
            )
        }

        var effects: [MediaGestureEffect] = []
        switch gesture.capturedAxis {
        case .undecided:
            break
        case .vertical:
            break
        case .horizontal(let direction):
            gesture.hasHorizontalVisualOffset = true
            effects.append(.visualOffset(gesture.cumulativeX))

            if gesture.surface == .compact, !gesture.requestedCompactCapability {
                gesture.requestedCompactCapability = true
                gesture.compactCapability = .pending
                effects.append(
                    .requestCompactCapability(
                        gestureID: gesture.id,
                        direction: direction
                    )
                )
            }

            let capability = capability(
                for: direction,
                gesture: gesture,
                previous: previous,
                next: next
            )
            applyArming(
                gesture: &gesture,
                direction: direction,
                capability: capability,
                effects: &effects
            )
        }

        activeGesture = gesture
        return effects
    }

    private func endGesture() -> [MediaGestureEffect] {
        guard let gesture = activeGesture else {
            return []
        }
        activeGesture = nil

        var effects: [MediaGestureEffect] = []
        switch gesture.capturedAxis {
        case .undecided:
            break
        case .horizontal(let direction):
            if gesture.isArmed {
                effects.append(.commit(direction))
            }
            effects.append(.resetVisualOffset)
        case .vertical:
            if let panelEffect = panelCommitEffect(for: gesture) {
                effects.append(panelEffect)
            }
        }
        return effects
    }

    private func cancelActiveGestureIfNeeded() -> [MediaGestureEffect] {
        guard let gesture = activeGesture else {
            return []
        }
        activeGesture = nil
        return gesture.hasHorizontalVisualOffset ? [.resetVisualOffset] : []
    }

    private func applyArming(
        gesture: inout ActiveGesture,
        direction: MediaGestureDirection,
        capability: MediaGestureCapability,
        effects: inout [MediaGestureEffect]
    ) {
        let distance = directionalDistance(for: gesture, direction: direction)
        let disarmBoundary = max(
            0,
            gesture.horizontalThreshold - Self.horizontalDisarmHysteresis
        )

        if gesture.isArmed {
            if distance <= disarmBoundary || capability != .supported {
                gesture.isArmed = false
            }
            return
        }

        guard
            capability == .supported,
            Self.reachedThreshold(distance, threshold: gesture.horizontalThreshold)
        else {
            return
        }
        gesture.isArmed = true
        effects.append(.requestArmHaptic)
    }

    private func capability(
        for direction: MediaGestureDirection,
        gesture: ActiveGesture,
        previous: MediaGestureCapability,
        next: MediaGestureCapability
    ) -> MediaGestureCapability {
        if gesture.surface == .compact {
            return gesture.compactCapability
        }

        switch direction {
        case .previous:
            return previous
        case .next:
            return next
        }
    }

    private func captureAxis(cumulativeX: Double, cumulativeY: Double) -> CapturedAxis {
        let absoluteX = abs(cumulativeX)
        let absoluteY = abs(cumulativeY)

        if absoluteX > 0, absoluteX >= absoluteY * Self.axisDominanceRatio {
            return .horizontal(cumulativeX < 0 ? .next : .previous)
        }
        if absoluteY > 0, absoluteY >= absoluteX * Self.axisDominanceRatio {
            return .vertical
        }
        return .undecided
    }

    private func directionalDistance(
        for gesture: ActiveGesture,
        direction: MediaGestureDirection
    ) -> Double {
        switch direction {
        case .previous:
            return max(0, gesture.cumulativeX)
        case .next:
            return max(0, -gesture.cumulativeX)
        }
    }

    private func panelCommitEffect(for gesture: ActiveGesture) -> MediaGestureEffect? {
        switch gesture.surface {
        case .compact:
            guard gesture.cumulativeY >= Self.verticalCommitThreshold else {
                return nil
            }
            return .requestExpansion
        case .expanded:
            guard gesture.cumulativeY <= -Self.verticalCommitThreshold else {
                return nil
            }
            return .requestCollapse
        }
    }

    private static func horizontalThreshold(for interactiveWidth: Double) -> Double {
        let finiteWidth = interactiveWidth.isFinite ? max(0, interactiveWidth) : 0
        return min(
            maximumHorizontalThreshold,
            max(minimumHorizontalThreshold, finiteWidth * horizontalThresholdRatio)
        )
    }

    private static func reachedThreshold(_ distance: Double, threshold: Double) -> Bool {
        distance + thresholdComparisonTolerance >= threshold
    }
}
