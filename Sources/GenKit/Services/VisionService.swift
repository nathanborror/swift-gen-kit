import Foundation

public protocol VisionService {
    func completion(request: VisionServiceRequest) async throws -> Message
    func completionStream(request: VisionServiceRequest, delta: (Message) async -> Void) async throws
}

public struct VisionServiceRequest {
    public var model: String
    public var messages: [Message]
    
    public init(model: String, messages: [Message]) {
        self.model = model
        self.messages = messages
    }
}
