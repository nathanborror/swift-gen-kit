import Foundation
import OSLog
import SharedKit
import GoogleGen

private let logger = Logger(subsystem: "GoogleService", category: "GenKit")

public final class GoogleService {
    
    private var client: GoogleGenClient
    
    public init(configuration: GoogleGenClient.Configuration) {
        self.client = GoogleGenClient(configuration: configuration)
        logger.info("GoogleGen Service: \(self.client.configuration.host.absoluteString)")
    }
}

extension GoogleService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = GenerateContentRequest(contents: encode(messages: request.messages))
        let result = try await client.chat(payload, model: request.model)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, update: (Message) async -> Void) async throws {
        let payload = GenerateContentRequest(contents: encode(messages: request.messages))
        let messageID = String.id
        for try await result in client.chatStream(payload, model: request.model) {
            var message = decode(result: result)
            message.id = messageID
            await update(message)
        }
    }
}

extension GoogleService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0, owner: "google") }
    }
}
