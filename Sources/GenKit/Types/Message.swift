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
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata?
    public var created: Date
    public var modified: Date
    
    public enum Role: String, CaseIterable, Codable, Sendable {
        case system, assistant, user, tool
    }

    public enum Content: Codable, Sendable {
        /// Text content
        case text(String)
        /// Image content needs to be base64 encoded data.
        case image(data: Data)
        /// Audio content needs to be base64 encoded data.
        case audio(data: Data, format: String)
    }

    public enum FinishReason: String, Codable, CaseIterable, Sendable {
        case stop, length, toolCalls, contentFilter, cancelled, error
    }
    
    public enum Attachment: Codable, Sendable {
        case agent(String)
        case file(String, String)
    }

    public init(id: Message.ID = .id, referenceID: String? = nil, runID: Run.ID? = nil, model: Model.ID? = nil,
                role: Role, content: [Content]? = nil, attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil,
                toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil, metadata: Metadata? = nil) {
        self.id = id
        self.referenceID = referenceID
        self.runID = runID
        self.model = model
        self.role = role
        self.content = content
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
        self.finishReason = finishReason
        self.metadata = metadata
        self.created = .now
        self.modified = .now
    }
}
