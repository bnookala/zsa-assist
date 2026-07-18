// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "zsa-assist",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ZSAAssistCore", targets: ["ZSAAssistCore"]),
        .library(name: "KeymappGRPC", targets: ["KeymappGRPC"]),
        .executable(name: "zsa-poller-demo", targets: ["PollerDemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "ZSAAssistCore"),
        .target(
            name: "KeymappGRPC",
            dependencies: [
                "ZSAAssistCore",
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
            ],
            plugins: [
                .plugin(name: "GRPCProtobufGenerator", package: "grpc-swift-protobuf")
            ]
        ),
        .executableTarget(
            name: "PollerDemo",
            dependencies: ["ZSAAssistCore", "KeymappGRPC"]
        ),
        .testTarget(name: "ZSAAssistCoreTests", dependencies: ["ZSAAssistCore"]),
    ]
)
