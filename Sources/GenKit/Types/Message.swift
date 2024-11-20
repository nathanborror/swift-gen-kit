import Foundation
import SharedKit

/// An abstract Message object used in a user interface and passed into any Service. Can be both encoded into an outgoing message or decoded from an
/// incoming message. Works with chat completion services or chat streaming services.
public struct Message: Codable, Identifiable, Sendable {
    public var id: ID<Message>
    public var model: Model.ID?
    public var parentID: String?
    public var role: Role
    public var content: [Content]?
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var runID: Run.ID?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata
    public var created: Date
    public var modified: Date
    
    public enum Role: String, Codable, Sendable {
        case system
        case assistant
        case user
        case tool
    }

    public enum Content: Codable, Sendable {
        case text(String)
        case image(Data)
        case imageURL(URL)
    }

    public enum FinishReason: Codable, Sendable {
        case stop
        case length
        case toolCalls
        case contentFilter
        case cancelled
    }
    
    public init(id: Message.ID = .id, model: Model.ID? = nil, parentID: String? = nil, role: Role, content: [Content]? = nil,
                toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: Run.ID? = nil, name: String? = nil,
                finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) {
        self.id = id
        self.model = model
        self.parentID = parentID
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.runID = runID
        self.name = name
        self.finishReason = finishReason
        self.metadata = .init(metadata)
        self.created = .now
        self.modified = .now
    }

    public init(id: Message.ID = .id, model: Model.ID? = nil, parentID: String? = nil, role: Role, content: String,
                toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: Run.ID? = nil, name: String? = nil,
                finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) {
        self.init(
            id: id,
            model: model,
            parentID: parentID,
            role: role,
            content: [.text(content)],
            toolCalls: toolCalls,
            toolCallID: toolCallID,
            runID: runID,
            name: name,
            finishReason: finishReason,
            metadata: metadata
        )
    }
}
