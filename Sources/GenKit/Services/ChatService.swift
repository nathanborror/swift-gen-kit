import Foundation
import SharedKit

public protocol ChatService: Sendable {
    func completion(_ request: ChatServiceRequest) async throws -> Message
    func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws
}

public struct ChatServiceRequest {
    public var model: Model
    public var messages: [Message]
    public var tools: [Tool]
    public var toolChoice: Tool?
    public var options: [String: Value]

    public init(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil, options: [String: Value] = [:]) {
        self.model = model
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
        self.options = options
    }
}

public enum ChatServiceError: Error, CustomStringConvertible {
    case requestError(String)
    case responseError(String)
    case unexpectedError(String)

    public var description: String {
        switch self {
        case .requestError(let detail):
            return "Request error: \(detail)"
        case .responseError(let detail):
            return "Response error: \(detail)"
        case .unexpectedError(let detail):
            return "Unexpected error: \(detail)"
        }
    }
}
