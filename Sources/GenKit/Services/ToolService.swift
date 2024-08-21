import Foundation

public protocol ToolService {
    func completion(request: ToolServiceRequest) async throws -> Message
    func completionStream(request: ToolServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct ToolServiceRequest {
    public var model: String
    public var messages: [Message]
    public var tool: Tool
    
    public init(model: String, messages: [Message], tool: Tool) {
        self.model = model
        self.messages = messages
        self.tool = tool
    }
}
