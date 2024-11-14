import Foundation

public protocol VisionService: Sendable {
    func completion(_ request: VisionServiceRequest) async throws -> Message
    func completionStream(_ request: VisionServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct VisionServiceRequest {
    public var model: Model
    public var messages: [Message]
    public var maxTokens: Int?
    public var temperature: Float?
    public var customHeaders: [String: String]

    public init(model: Model, messages: [Message], maxTokens: Int? = nil, temperature: Float? = nil, customHeaders: [String: String] = [:]) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.customHeaders = customHeaders
    }
}
