// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
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
        .executable(name: "GenCmd", targets: ["GenCmd"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathanborror/swift-json", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-shared-kit", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-openai", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-ollama", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-mistral", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-anthropic", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-perplexity", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-elevenlabs", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-fal", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .target(name: "GenKit", dependencies: [
            "GenMacro",
            .product(name: "JSON", package: "swift-json"),
            .product(name: "SharedKit", package: "swift-shared-kit"),
            .product(name: "OpenAI", package: "swift-openai"),
            .product(name: "Ollama", package: "swift-ollama"),
            .product(name: "Mistral", package: "swift-mistral"),
            .product(name: "Perplexity", package: "swift-perplexity"),
            .product(name: "Anthropic", package: "swift-anthropic"),
            .product(name: "ElevenLabs", package: "swift-elevenlabs"),
            .product(name: "Fal", package: "swift-fal"),
        ]),
        .executableTarget(name: "GenCmd", dependencies: [
            "GenKit",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .macro(
            name: "GenMacro",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(name: "GenKitTests", dependencies: ["GenKit"]),
    ]
)
