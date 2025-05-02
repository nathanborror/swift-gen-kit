import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

public actor PerplexityService {
    
    private let client: Perplexity.Client

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
    }
}

extension PerplexityService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: (request.temperature != nil) ? Float(request.temperature!) : nil
        )
        let result = try await client.chat(req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: (request.temperature != nil) ? Float(request.temperature!) : nil,
            stream: true
        )
        var message = Message(role: .assistant)
        for try await result in try client.chatStream(req) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension PerplexityService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(id: $0.id, name: $0.name, owner: $0.owner, contextWindow: $0.contextWindow)
        }
    }
}
