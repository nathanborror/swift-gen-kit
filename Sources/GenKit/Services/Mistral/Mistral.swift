import Foundation
import OSLog
import MistralKit

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

public final class MistralService: ChatService {
    
    let client: MistralClient
    
    public init(token: String) {
        self.client = MistralClient(token: token)
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
