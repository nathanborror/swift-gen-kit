import Foundation
import OSLog
import Ollama

private let logger = Logger(subsystem: "OllamaService", category: "GenKit")

public actor OllamaService {
    
    private var client: Ollama.Client

    public init(host: URL? = nil) {
        self.client = .init(host: host)
    }
}

extension OllamaService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            model: request.model.id,
            messages: request.messages.map { .init($0) },
            tools: request.tools.map { .init($0) },
            stream: false
        )
        let resp = try await client.chatCompletions(req)
        return .init(resp)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatRequest(
            model: request.model.id,
            messages: request.messages.map { .init($0) },
            tools: request.tools.map { .init($0) },
            stream: true
        )
        var message = Message(role: .assistant)
        for try await resp in try client.chatCompletionsStream(req) {
            message.patch(resp)
            try await update(message)
            
            // The connection hangs if we don't explicitly return when the stream has stopped.
            if message.finishReason == .stop {
                return
            }
        }
    }
}

extension OllamaService: EmbeddingService {
    
    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = EmbeddingsRequest(model: request.model.id, input: request.input)
        let result = try await client.embeddings(req)
        return result.embedding
    }
}

extension OllamaService: ModelService {
    
    public func models() async throws -> [Model] {
        let resp = try await client.models()
        return resp.models.map { .init($0) }
    }
}
