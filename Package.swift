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
        .package(url: "https://github.com/nathanborror/swift-openai", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-ollama", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-mistral", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-perplexity", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-anthropic", branch: "main"),
    ],
    targets: [
        .target(name: "GenKit", dependencies: [
            .product(name: "SharedKit", package: "SharedKit"),
            .product(name: "OpenAI", package: "swift-openai"),
            .product(name: "Ollama", package: "swift-ollama"),
            .product(name: "Mistral", package: "swift-mistral"),
            .product(name: "Perplexity", package: "swift-perplexity"),
            .product(name: "Anthropic", package: "swift-anthropic"),
        ]),
        .testTarget(name: "GenKitTests", dependencies: ["GenKit"]),
    ]
)
