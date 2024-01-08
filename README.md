# Swift GenKit

GenKit is a library that abstracts away all the differences across generative AI platforms. It's sort of like a lightweight [LangChain](https://www.langchain.com) for Swift.

### Services

- [Chat Service](https://github.com/nathanborror/swift-gen-kit/blob/main/Sources/GenKit/Services/ChatService.swift)
- [Embedding Service](https://github.com/nathanborror/swift-gen-kit/blob/main/Sources/GenKit/Services/EmbeddingService.swift)
- [Image Service](https://github.com/nathanborror/swift-gen-kit/blob/main/Sources/GenKit/Services/ImageService.swift)
- [Model Service](https://github.com/nathanborror/swift-gen-kit/blob/main/Sources/GenKit/Services/ModelService.swift)
- [Transcription Service](https://github.com/nathanborror/swift-gen-kit/blob/main/Sources/GenKit/Services/TranscriptionService.swift)

### Supported Platforms

- [Mistral](https://github.com/nathanborror/swift-mistral) (chats, embeddings, models)
- [Ollama](https://github.com/nathanborror/swift-ollama) (chats, embeddings, models)
- [OpenAI](https://github.com/nathanborror/swift-openai) (chats, embeddings, models, images, transcriptions)
- [Perplexity](https://github.com/nathanborror/swift-perplexity) (chats, models)
- [Anthropic](https://github.com/nathanborror/swift-anthropic) (chats, models)
