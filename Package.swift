// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchHub",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NotchHub", targets: ["NotchHubApp"]),
        .executable(name: "MediaTransportCandidate", targets: ["MediaTransportCandidate"])
    ],
    targets: [
        .target(name: "NotchHubCore"),
        .target(name: "NotchHubMediaCore"),
        .executableTarget(
            name: "NotchHubApp",
            dependencies: ["NotchHubCore"]
        ),
        .executableTarget(
            name: "MediaTransportCandidate",
            dependencies: ["NotchHubMediaCore"],
            path: "Tools/ProductionMediaTransportCandidate/CLI"
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
            name: "NotchHubMediaCoreTests",
            dependencies: ["NotchHubMediaCore"]
        ),
        .testTarget(
            name: "MediaBridgeProbeCoreTests",
            dependencies: ["MediaBridgeProbeCore"],
            path: "Tests/MediaBridgeProbeCoreTests"
        )
    ]
)
