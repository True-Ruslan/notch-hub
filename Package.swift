// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchHub",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NotchHub", targets: ["NotchHubApp"])
    ],
    targets: [
        .target(name: "NotchHubCore"),
        .executableTarget(
            name: "NotchHubApp",
            dependencies: ["NotchHubCore"]
        ),
        .target(
            name: "MediaBridgeProbeCore",
            path: "Tools/MediaBridgeProbe/Core"
        ),
        .executableTarget(
            name: "MediaBridgeProbe",
            dependencies: ["MediaBridgeProbeCore"],
            path: "Tools/MediaBridgeProbe/CLI"
        ),
        .testTarget(
            name: "NotchHubCoreTests",
            dependencies: ["NotchHubCore"]
        ),
        .testTarget(
            name: "MediaBridgeProbeCoreTests",
            dependencies: ["MediaBridgeProbeCore"],
            path: "Tests/MediaBridgeProbeCoreTests"
        )
    ]
)
