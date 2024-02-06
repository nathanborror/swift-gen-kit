import Foundation

public protocol VisionService {
    func completion(request: VisionServiceRequest) async throws -> Message
    func completionStream(request: VisionServiceRequest, delta: (Message) async -> Void) async throws
}

public struct VisionServiceRequest {
    public var model: String
    public var messages: [Message]
    public var maxTokens: Int?
    
    public init(model: String, messages: [Message], maxTokens: Int? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
    }
}
