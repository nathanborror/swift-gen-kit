import Foundation
import OSLog
import OllamaKit

private let logger = Logger(subsystem: "OllamaService", category: "GenKit")

public final class OllamaService: ChatService {
    
    public static var shared: OllamaService = {
        guard let host = Bundle.main.infoDictionary?["OllamaHost"] as? String else {
            fatalError("missing OllamaHost setting in Info.plist")
        }
        guard let url = URL(string: host) else {
            fatalError("bad OllamaHost string")
        }
        return OllamaService(url: url)
    }()
    
    private var client: OllamaClient
    
    init(url: URL) {
        self.client = OllamaClient(url: url)
        logger.debug("Ollama Host: \(url.absoluteString)")
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
