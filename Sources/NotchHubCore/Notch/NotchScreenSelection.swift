enum NotchScreenSelection {
    static func preferredIndex(
        in screens: [ScreenGeometryInput],
        fallbackIndex: Int?
    ) -> Int? {
        if let hardwareNotchIndex = screens.firstIndex(where: {
            NotchGeometry.detectedHardwareNotch(in: $0) != nil
        }) {
            return hardwareNotchIndex
        }

        if let fallbackIndex, screens.indices.contains(fallbackIndex) {
            return fallbackIndex
        }

        return screens.indices.first
    }
}
