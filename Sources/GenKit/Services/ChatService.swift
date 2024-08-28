import Foundation

public protocol ChatService: Sendable {
    func completion(request: ChatServiceRequest) async throws -> Message
    func completionStream(request: ChatServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct ChatServiceRequest {
    public var model: String
    public var messages: [Message]
    public var tools: [Tool]
    public var toolChoice: Tool?
    
    public init(model: String, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
    }
}
