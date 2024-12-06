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
    public var context: [String: String]?
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata?
    public var created: Date
    public var modified: Date

    public enum Kind: String, CaseIterable, Codable, Sendable {
        /// Instructions are sent to APIs but not shown in the UI (unless in a debug mode).
        case instruction
        /// Local messages are never sent to an API but always displayed in the UI.
        case local
        /// Error messages are never sent to an API but always displayed in the UI.
        case error
        /// Messages without a `kind` are always sent to APIs and always shown in the UI.
        case none
    }
    
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
        case asset(Asset)
        case agent(String)
        case automation(String)
        case component(Component)
        case file(String, String)
    }
    
    public struct Component: Codable, Sendable {
        public var name: String
        public var json: String
        
        public init(name: String, json: String) {
            self.name = name
            self.json = json
        }
    }
    
    public init(id: Message.ID = .id, parent: String? = nil, kind: Kind = .none, role: Role, content: [Content]? = nil,
                context: [String: String]? = nil, attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil, toolCallID: String? = nil,
                runID: Run.ID? = nil, name: String? = nil, finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) {
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
