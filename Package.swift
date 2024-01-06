// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "GenKit", targets: ["GenKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathanborror/SharedKit", branch: "main"),
        .package(url: "https://github.com/nathanborror/OpenAI", branch: "main"),
        .package(url: "https://github.com/nathanborror/OllamaKit", branch: "main"),
        .package(url: "https://github.com/nathanborror/MistralKit", branch: "main"),
        .package(url: "https://github.com/nathanborror/PerplexityKit", branch: "main"),
    ],
    targets: [
        .target(name: "GenKit", dependencies: [
            .product(name: "SharedKit", package: "SharedKit"),
            .product(name: "OpenAI", package: "OpenAI"),
            .product(name: "OllamaKit", package: "OllamaKit"),
            .product(name: "MistralKit", package: "MistralKit"),
            .product(name: "PerplexityKit", package: "PerplexityKit"),
        ]),
        .testTarget(name: "GenKitTests", dependencies: ["GenKit"]),
    ]
)
