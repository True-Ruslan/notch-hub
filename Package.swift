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
        .testTarget(
            name: "NotchHubCoreTests",
            dependencies: ["NotchHubCore"]
        )
    ]
)
