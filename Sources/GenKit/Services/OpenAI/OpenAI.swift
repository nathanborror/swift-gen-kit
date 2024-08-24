import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public final class OpenAIService {
    
    private var client: OpenAIClient
    
    public init(configuration: OpenAIClient.Configuration) {
        self.client = OpenAIClient(configuration: configuration)
        logger.info("OpenAI Service: \(self.client.configuration.host.absoluteString)")
    }
    
    private func makeRequest(model: String, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil, stream: Bool = false) -> ChatQuery {
        return .init(
            model: model,
            messages: encode(messages: messages),
            tools: encode(tools: tools),
            toolChoice: encode(toolChoice: toolChoice),
            stream: stream
        )
    }
}

extension OpenAIService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice)
        let result = try await client.chats(query: payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice)
        var message = Message(role: .assistant)
        for try await result in client.chatsStream(query: payload) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension OpenAIService: EmbeddingService {
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let query = EmbeddingsQuery(model: model, input: input)
        let result = try await client.embeddings(query: query)
        return result.data.first?.embedding ?? []
    }
}

extension OpenAIService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { Model(id: $0.id, owner: $0.ownedBy) }
    }
}

extension OpenAIService: ImageService {
    
    public func imagine(request: ImagineServiceRequest) async throws -> [Data] {
        let query = ImagesQuery(
            prompt: request.prompt,
            model: request.model,
            n: request.n,
            size: request.size
        )
        let result = try await client.images(query: query)
        
        // HACK: Wait for a second for the images to be available on OpenAI's CDN. Without this the URLs in the
        // result may fail.
        let seconds = 1
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        
        if let data = result.data {
            return try data.map {
                guard let url = $0.url else { return nil }
                let remoteURL = URL(string: url)!
                return try Data(contentsOf: remoteURL)
            }.compactMap { $0 }
        } 
        throw ServiceError.missingImageData
    }
}

extension OpenAIService: TranscriptionService {
    
    public func transcribe(request: TranscriptionServiceRequest) async throws -> String {
        let query = AudioTranscriptionQuery(
            file: request.data,
            model: request.model,
            prompt: request.prompt,
            temperature: request.temperature,
            language: request.language,
            responseFormat: encode(responseFormat: request.responseFormat)
        )
        let result = try await client.audioTranscriptions(query: query)
        return result.text
    }
}

extension OpenAIService: VisionService {
    
    public func completion(request: VisionServiceRequest) async throws -> Message {
        let query = ChatVisionQuery(
            model: request.model,
            messages: encode(visionMessages: request.messages),
            maxTokens: request.maxTokens
        )
        let result = try await client.chatsVision(query: query)
        return decode(result: result)
    }
    
    public func completionStream(request: VisionServiceRequest, update: (Message) async throws -> Void) async throws {
        let query = ChatVisionQuery(
            model: request.model,
            messages: encode(visionMessages: request.messages),
            maxTokens: request.maxTokens
        )
        var message = Message(role: .assistant)
        for try await result in client.chatsVisionStream(query: query) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension OpenAIService: SpeechService {
    
    public func speak(request: SpeechServiceRequest) async throws -> Data {
        let query = AudioSpeechQuery(
            model: request.model,
            input: request.input,
            voice: .init(rawValue: request.voice) ?? .alloy,
            responseFormat: try encode(responseFormat: request.responseFormat),
            speed: request.speed
        )
        let result = try await client.audioSpeech(query: query)
        return result
    }
}

extension OpenAIService: ToolService {
    
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool)
        let result = try await client.chats(query: payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ToolServiceRequest, update: (Message) async throws -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatsStream(query: payload) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}
