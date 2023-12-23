import Foundation
import OSLog
import OllamaKit

private let logger = Logger(subsystem: "OllamaService", category: "GenKit")

public final class OllamaService: ChatService {
    
    public static var shared: OllamaService = {
        let host = Bundle.main.infoDictionary?["OllamaHost"] as? String
        return OllamaService(host: host)
    }()
    
    private var client: OllamaClient
    
    init(host: String? = nil) {
        self.client = OllamaClient(host: host ?? "")
        logger.debug("Ollama Host: \(host ?? "default")")
    }
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages))
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages), stream: true)
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = messageID
            await delta(message)
        }
    }
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let payload = EmbeddingRequest(model: model, prompt: input, options: [:])
        let result = try await client.embeddings(payload)
        return result.embedding
    }
}
