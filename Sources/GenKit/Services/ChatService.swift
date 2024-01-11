import Foundation

public protocol ChatService {
    func completion(request: ChatServiceRequest) async throws -> Message
    func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws
}

public struct ChatServiceRequest {
    public var model: String
    public var messages: [Message]
    public var tools: Set<Tool>
    public var toolChoice: Tool?
    
    public init(model: String, messages: [Message], tools: Set<Tool> = [], toolChoice: Tool? = nil) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
    }
}
