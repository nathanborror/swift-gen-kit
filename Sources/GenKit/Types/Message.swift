import Foundation
import SharedKit

/// An abstract Message object used in a user interface and passed into any Service. Can be both encoded into an outgoing message or decoded from an
/// incoming message. Works with chat completion services or chat streaming services.
public struct Message: Codable, Identifiable, Sendable {
    public var id: ID<Message>
    public var referenceID: String?
    public var runID: Run.ID?
    public var model: Model.ID?
    public var role: Role
    public var content: [Content]?
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata?
    public var created: Date
    public var modified: Date
    
    public enum Role: String, Codable, Sendable {
        case system
        case assistant
        case user
        case tool
    }

    /// Types of content that can be interleaved into a user message. All other roles always respond with text.
    public enum Content: Codable, Sendable {
        case text(String)
        case image(Data)
        case imageURL(URL)
    }

    /// The reason the model stopped generating tokens.
    public enum FinishReason: Codable, Sendable {
        case stop
        case length
        case tool_calls
        case content_filter
        case user_cancelled
        case error
    }

    public init(id: Message.ID = .id, referenceID: String? = nil, runID: Run.ID? = nil, model: Model.ID? = nil,
                role: Role, content: [Content]? = nil, toolCalls: [ToolCall]? = nil, toolCallID: String? = nil,
                name: String? = nil, finishReason: FinishReason? = nil, metadata: Metadata? = nil) {
        self.id = id
        self.referenceID = referenceID
        self.runID = runID
        self.model = model
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
        self.finishReason = finishReason
        self.metadata = metadata
        self.created = .now
        self.modified = .now
    }
}
