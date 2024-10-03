import Foundation
import OSLog
import SharedKit
import GoogleGen

private let logger = Logger(subsystem: "GoogleService", category: "GenKit")

public actor GoogleService {
    
    private var client: GoogleGenClient
    
    public init(configuration: GoogleGenClient.Configuration) {
        self.client = GoogleGenClient(configuration: configuration)
    }
}

extension GoogleService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = GenerateContentRequest(contents: encode(messages: request.messages))
        let result = try await client.chat(req, model: request.model.id)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = GenerateContentRequest(contents: encode(messages: request.messages))
        let messageID = String.id
        for try await result in try client.chatStream(req, model: request.model.id) {
            var message = decode(result: result)
            message.id = messageID
            try await update(message)
        }
    }
}

extension GoogleService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0, owner: "google") }
    }
}
