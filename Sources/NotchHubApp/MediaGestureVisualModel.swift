import CoreGraphics
import NotchHubMediaCore
import SwiftUI

@MainActor
final class MediaGestureVisualModel: ObservableObject {
    @Published private(set) var horizontalOffset: CGFloat = 0

    func setHorizontalOffset(_ value: CGFloat, surface: MediaGestureSurface) {
        let scale: CGFloat
        let limit: CGFloat

        switch surface {
        case .compact:
            scale = 0.25
            limit = 18
        case .peek:
            scale = 0.35
            limit = 36
        case .expanded:
            scale = 0.50
            limit = 72
        }

        horizontalOffset = min(limit, max(-limit, value * scale))
    }

    func reset(animated: Bool = false) {
        if animated {
            withAnimation(.easeOut(duration: 0.16)) {
                horizontalOffset = 0
            }
        } else {
            horizontalOffset = 0
        }
    }
}
