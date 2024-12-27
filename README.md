# Swift GenKit

GenKit abstracts away differences across ai model provider platforms. The goal is to make native Swift prototyping and development with ai fast, easy and fun!

## Swift Package Manager

```swift
...
dependencies: [
    .package(url: "https://github.com/nathanborror/swift-gen-kit", branch: "main"),
],
targets: [
    .target(
        name: "YOUR_TARGET",
        dependencies: [
            .product(name: "GenKit", package: "swift-gen-kit"),
        ]
    ),
],
...
```

## Usage

Establish the service and model you want to use:

```swift
let service = AnthropicService(apiKey: "ANTHROPIC_API_KEY")
let model = Model(id: "claude-3-5-sonnet-20240620")
```

An example chat completion that just generates a single response:

```swift
let request = ChatServiceRequest(
    model: model,
    messages: [
        Message(role: .system, content: "You are a helpful assistant."),
        Message(role: .user, content: "Hello!"),
    ]
)
let message = try await service.completion(request)
print(message)
```

An streaming session example that may perform multiple generations in a loop if tools are present:

```swift
var request = ChatSessionRequest(service: service, model: model)
request.with(system: "You are a helpful assistant.")
request.with(history: [Message(role: .user, content: "Hello!")])

let stream = ChatSession.shared.completionStream(request)
for try await message in stream {
    print(message.content)
}
```

## Demo App

[Heat](https://github.com/nathanborror/Heat) is an example of how GenKit can be implemented.

## Features

### Sessions

Sessions are the highest level of abstraction and the easiest to use. They run in a loop and call out to tools as needed and send tool responses back to the model until it completes its work.

### Services

Services are a common interface for working across many platforms. They allow you to seamlessly switch out the underlying platform without changing any code.

- [Chat Service](Sources/GenKit/Services/ChatService.swift)
- [Embedding Service](Sources/GenKit/Services/EmbeddingService.swift)
- [Image Service](Sources/GenKit/Services/ImageService.swift)
- [Model Service](Sources/GenKit/Services/ModelService.swift)
- [Transcription Service](Sources/GenKit/Services/TranscriptionService.swift)
- [Speech Service](Sources/GenKit/Services/SpeechService.swift)

### Supported Providers

Provider packages are swift interfaces that talk directly to model provider REST APIs. You can use these directly but their APIs vary slightly.

- [Anthropic](/nathanborror/swift-anthropic)
- [ElevenLabs](/nathanborror/swift-elevenlabs)
- [Fal](/nathanborror/swift-fal)
- [Mistral](/nathanborror/swift-mistral)
- [Ollama](/nathanborror/swift-ollama)
- [OpenAI](/nathanborror/swift-openai)
- [Perplexity](/nathanborror/swift-perplexity)
