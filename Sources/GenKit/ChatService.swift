import Foundation

public protocol ChatService {
    func completion(request: ChatServiceRequest) async throws -> Message
    func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws
    
    func embeddings(model: String, input: String) async throws -> [Double]
}

public struct ChatServiceRequest {
    public var model: String
    public var messages: [Message]
    public var tools: [Tool]
    public var toolChoice: Tool?
}
