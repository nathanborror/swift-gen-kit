import Foundation

public protocol ToolService: Sendable {
    func completion(request: ToolServiceRequest) async throws -> Message
    func completionStream(request: ToolServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct ToolServiceRequest {
    public var model: Model
    public var messages: [Message]
    public var tool: Tool
    public var temperature: Float?
    
    public init(model: Model, messages: [Message], tool: Tool, temperature: Float? = nil) {
        self.model = model
        self.messages = messages
        self.tool = tool
        self.temperature = temperature
    }
}
