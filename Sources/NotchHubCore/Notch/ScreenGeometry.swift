import AppKit

public struct ScreenGeometryInput: Equatable, Sendable {
    public let frame: CGRect
    public let safeAreaTop: CGFloat
    public let auxiliaryTopLeftArea: CGRect?
    public let auxiliaryTopRightArea: CGRect?
    public let displayUUID: String?

    public init(
        frame: CGRect,
        safeAreaTop: CGFloat,
        auxiliaryTopLeftArea: CGRect?,
        auxiliaryTopRightArea: CGRect?,
        displayUUID: String? = nil
    ) {
        self.frame = frame
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeftArea = auxiliaryTopLeftArea
        self.auxiliaryTopRightArea = auxiliaryTopRightArea
        self.displayUUID = displayUUID
    }
}

public extension ScreenGeometryInput {
    @MainActor
    init(screen: NSScreen) {
        self.init(
            frame: screen.frame,
            safeAreaTop: screen.safeAreaInsets.top,
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea,
            displayUUID: Self.stableDisplayUUID(for: screen)
        )
    }

    @MainActor
    static func stableDisplayUUID(for screen: NSScreen) -> String? {
        guard
            let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber
        else {
            return nil
        }
        let displayID = CGDirectDisplayID(truncating: screenNumber)
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue()
        else {
            return nil
        }
        return CFUUIDCreateString(nil, cfUUID) as String?
    }
}
