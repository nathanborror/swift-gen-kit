import Foundation

public protocol ChatService: Sendable {
    func completion(_ request: ChatServiceRequest) async throws -> Message
    func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct ChatServiceRequest {
    public var model: Model
    public var messages: [Message]
    public var tools: [Tool]
    public var toolChoice: Tool?
    public var temperature: Float?
    
    public init(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil, temperature: Float? = nil) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
        self.temperature = temperature
    }
}
