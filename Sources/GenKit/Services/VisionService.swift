import Foundation

public protocol VisionService: Sendable {
    func completion(request: VisionServiceRequest) async throws -> Message
    func completionStream(request: VisionServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct VisionServiceRequest {
    public var model: Model
    public var messages: [Message]
    public var maxTokens: Int?
    
    public init(model: Model, messages: [Message], maxTokens: Int? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
    }
}
