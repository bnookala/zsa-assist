// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "zsa-assist",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ZSAAssistCore", targets: ["ZSAAssistCore"]),
        .executable(name: "zsa-poller-demo", targets: ["PollerDemo"]),
    ],
    targets: [
        .target(name: "ZSAAssistCore"),
        .executableTarget(name: "PollerDemo", dependencies: ["ZSAAssistCore"]),
        .testTarget(name: "ZSAAssistCoreTests", dependencies: ["ZSAAssistCore"]),
    ]
)
