import Foundation
import OSLog
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

public final class MistralService {
    
    let client: MistralClient
    
    public init(configuration: MistralClient.Configuration) {
        self.client = MistralClient(configuration: configuration)
        logger.info("Mistral Service: \(self.client.configuration.host.absoluteString)")
    }
}

extension MistralService: ChatService {
    
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

extension MistralService: EmbeddingService {
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let payload = EmbeddingRequest(model: model, input: [input])
        let result = try await client.embeddings(payload)
        return result.data.first?.embedding ?? []
    }
}

extension MistralService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { Model(id: $0.id, owner: $0.ownedBy) }
    }
}
