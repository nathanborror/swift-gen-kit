import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public actor OpenAIService {
    
    private var client: OpenAIClient
    
    public init(configuration: OpenAIClient.Configuration) {
        self.client = OpenAIClient(configuration: configuration)
    }
}

extension OpenAIService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatQuery(
            model: request.model.id.rawValue,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice),
            temperature: request.temperature
        )
        let result = try await client.chats(query: req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatQuery(
            model: request.model.id.rawValue,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice),
            temperature: request.temperature
        )
        var message = Message(role: .assistant)
        for try await result in client.chatsStream(query: req) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension OpenAIService: EmbeddingService {
    
    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = EmbeddingsQuery(model: request.model.id.rawValue, input: request.input)
        let result = try await client.embeddings(query: req)
        return result.data.first?.embedding ?? []
    }
}

extension OpenAIService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode(model: $0) }
    }
}

extension OpenAIService: ImageService {
    
    public func imagine(_ request: ImagineServiceRequest) async throws -> [Data] {
        let req = ImagesQuery(
            prompt: request.prompt,
            model: request.model.id.rawValue,
            n: request.n,
            size: request.size
        )
        let result = try await client.images(query: req)
        
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
    
    public func transcribe(_ request: TranscriptionServiceRequest) async throws -> String {
        let req = AudioTranscriptionQuery(
            file: request.data,
            model: request.model.id.rawValue,
            prompt: request.prompt,
            temperature: request.temperature,
            language: request.language,
            responseFormat: encode(responseFormat: request.responseFormat)
        )
        let result = try await client.audioTranscriptions(query: req)
        return result.text
    }
}

extension OpenAIService: SpeechService {
    
    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        let req = AudioSpeechQuery(
            model: request.model.id.rawValue,
            input: request.input,
            voice: .init(rawValue: request.voice) ?? .alloy,
            responseFormat: try encode(responseFormat: request.responseFormat),
            speed: request.speed
        )
        let result = try await client.audioSpeech(query: req)
        return result
    }
}
