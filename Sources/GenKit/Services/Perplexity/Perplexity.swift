import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

public final class PerplexityService: ChatService {
    
    let client: PerplexityClient
    
    public init(token: String) {
        self.client = PerplexityClient(token: token)
    }
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages))
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages), stream: true)
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = result.id
            await delta(message)
        }
    }
}

extension PerplexityService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0, owner: "perplexity") }
    }
}
