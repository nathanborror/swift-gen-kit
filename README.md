# Swift GenKit

GenKit is a library that abstracts away all the differences across generative AI platforms. It's sort of like a lightweight [LangChain](https://www.langchain.com) for Swift. The goal is to make native Swift development with generative AI fast, easy and fun!

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
- [Tool Service](Sources/GenKit/Services/ToolService.swift)
- [Vision Service](Sources/GenKit/Services/VisionService.swift)
- [Speech Service](Sources/GenKit/Services/SpeechService.swift)

### Supported Providers

Provider packages are swift interfaces that talk directly to model provider REST APIs. You can use these directly but their APIs vary slightly.

- [Mistral](https://github.com/nathanborror/swift-mistral) (chats, embeddings, models)
- [Ollama](https://github.com/nathanborror/swift-ollama) (chats, embeddings, models, vision)
- [OpenAI](https://github.com/nathanborror/swift-openai) (chats, embeddings, models, images, transcriptions, vision, speech)
- [Perplexity](https://github.com/nathanborror/swift-perplexity) (chats, models)
- [Anthropic](https://github.com/nathanborror/swift-anthropic) (chats, models)
- [ElevenLabs](https://github.com/nathanborror/swift-elevenlabs) (speech, models)
- [Google](https://github.com/nathanborror/swift-google-gen) (chat, models)

### Example Usage

[Heat](https://github.com/nathanborror/Heat) is a good example of how GenKit can be used.
