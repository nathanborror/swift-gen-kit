import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public actor OpenAIService {
    
    private var client: OpenAI.Client

    public init(host: URL? = nil, apiKey: String) {
        self.client = .init(host: host, apiKey: apiKey)
    }
}

extension OpenAIService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            messages: encode(messages: request.messages),
            model: request.model.id.rawValue,
            temperature: request.temperature,
            tools: encode(tools: request.tools),
            tool_choice: encode(toolChoice: request.toolChoice)
        )
        let resp = try await client.chatCompletions(req)
        guard let message = Message(resp) else {
            throw ChatServiceError.responseError("Missing response choice")
        }
        return message
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = OpenAI.ChatRequest(
            messages: encode(messages: request.messages),
            model: request.model.id.rawValue,
            stream: true,
            temperature: request.temperature,
            tools: encode(tools: request.tools),
            tool_choice: encode(toolChoice: request.toolChoice)
        )
        var message = Message(role: .assistant)
        for try await resp in try client.chatCompletionsStream(req) {
            message.patch(with: resp)
            try await update(message)
        }
    }
}

extension OpenAIService: EmbeddingService {

    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = OpenAI.EmbeddingsRequest(
            input: request.input,
            model: request.model.id.rawValue
        )
        let result = try await client.embeddings(req)
        return result.data.first?.embedding ?? []
    }
}

extension OpenAIService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { .init($0) }
    }
}

extension OpenAIService: ImageService {
    
    public func imagine(_ request: ImagineServiceRequest) async throws -> [Data] {
        let req = OpenAI.ImageRequest(
            prompt: request.prompt,
            model: request.model.id.rawValue,
            n: request.n,
            size: .size_1024x1024
        )
        let result = try await client.imagesGenerations(req)

        // HACK: Wait for a second for the images to be available on OpenAI's CDN. Without this the URLs in the
        // result may fail.
        let seconds = 1
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        
        return try result.data.map {
            guard let url = $0.url else { return nil }
            let remoteURL = URL(string: url)!
            return try Data(contentsOf: remoteURL)
        }.compactMap { $0 }
    }
}

extension OpenAIService: TranscriptionService {
    
    public func transcribe(_ request: TranscriptionServiceRequest) async throws -> String {
        let req = OpenAI.TranscriptionRequest(
            file: request.data,
            model: request.model.id.rawValue,
            language: request.language,
            prompt: request.prompt,
            response_format: (request.responseFormat != nil) ? .init(rawValue: request.responseFormat!) : nil,
            temperature: request.temperature
        )
        let result = try await client.transcriptions(req)
        return result.text
    }
}

extension OpenAIService: SpeechService {
    
    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        let req = OpenAI.SpeechRequest(
            model: request.model.id.rawValue,
            input: request.input,
            voice: .init(rawValue: request.voice) ?? .alloy,
            response_format: (request.responseFormat != nil) ? .init(rawValue: request.responseFormat!) : nil,
            speed: request.speed
        )
        return try await client.speech(req)
    }
}
