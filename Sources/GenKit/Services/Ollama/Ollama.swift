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
            model: request.model.id.rawValue,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            stream: false
        )
        let result = try await client.chat(req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        
        // Ollama doesn't yet support streaming when tools are present.
        guard request.tools.isEmpty else {
            let message = try await completion(request)
            try await update(message)
            return
        }
        
        let req = ChatRequest(
            model: request.model.id.rawValue,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            stream: request.tools.isEmpty
        )
        var message = Message(role: .assistant)
        for try await result in client.chatStream(req) {
            message = decode(result: result, into: message)
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
        let req = EmbeddingRequest(model: request.model.id.rawValue, input: request.input)
        let result = try await client.embeddings(req)
        return result.embedding
    }
}

extension OllamaService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { decode(model: $0) }
    }
}
