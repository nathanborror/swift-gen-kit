// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-gen-kit",
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
        .package(url: "https://github.com/nathanborror/swift-shared-kit", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-openai", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-ollama", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-mistral", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-anthropic", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-perplexity", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-elevenlabs", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-fal", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-llama", branch: "main"),
        .package(url: "https://github.com/loopwork-ai/JSONSchema", from: "1.0.0"),
    ],
    targets: [
        .target(name: "GenKit", dependencies: [
            .product(name: "SharedKit", package: "swift-shared-kit"),
            .product(name: "OpenAI", package: "swift-openai"),
            .product(name: "Ollama", package: "swift-ollama"),
            .product(name: "Mistral", package: "swift-mistral"),
            .product(name: "Perplexity", package: "swift-perplexity"),
            .product(name: "Anthropic", package: "swift-anthropic"),
            .product(name: "ElevenLabs", package: "swift-elevenlabs"),
            .product(name: "Fal", package: "swift-fal"),
            .product(name: "Llama", package: "swift-llama"),
            .product(name: "JSONSchema", package: "JSONSchema"),
        ]),
        .testTarget(name: "GenKitTests", dependencies: ["GenKit"]),
    ]
)
