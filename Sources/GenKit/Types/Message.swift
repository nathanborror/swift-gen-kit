import Foundation
import SharedKit

public struct Message: Codable, Identifiable, Sendable {
    public var id: ID<Message>
    public var parent: String?
    public var kind: Kind
    public var role: Role
    public var content: String?
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var runID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata
    public var created: Date
    public var modified: Date
    
    public enum Kind: String, Codable, Sendable {
        /// Instructions are sent to APIs but not shown in the UI (unless in a debug mode).
        case instruction
        /// Local messages are never sent to an API but always displayed in the UI.
        case local
        /// Error messages are never sent to an API but always displayed in the UI.
        case error
        /// Messages without a `kind` are always sent to APIs and always shown in the UI.
        case none
    }
    
    public enum Role: String, Codable, Sendable {
        case system, assistant, user, tool
    }
    
    public enum FinishReason: Codable, Sendable {
        case stop, length, toolCalls, contentFilter, cancelled
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
    
    public init(id: Message.ID = .id, parent: String? = nil, kind: Kind = .none, role: Role, content: String? = nil,
                attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil, toolCallID: String? = nil,
                runID: String? = nil, name: String? = nil, finishReason: FinishReason? = .stop,
                metadata: [String: String] = [:]) {
        self.id = id
        self.parent = parent
        self.kind = kind
        self.role = role
        self.content = content
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.runID = runID
        self.name = name
        self.finishReason = finishReason
        self.metadata = .init(metadata)
        self.created = .now
        self.modified = .now
    }

    
    public static func system(parent: String? = nil, kind: Kind = .none, content: String? = nil, attachments: [Attachment] = [],
                            toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: String? = nil, name: String? = nil,
                            finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) -> Self {
        self.init(parent: parent, kind: kind, role: .system, content: content, attachments: attachments, toolCalls: toolCalls,
              toolCallID: toolCallID, runID: runID, name: name, finishReason: finishReason, metadata: metadata)
    }
    
    public static func assistant(parent: String? = nil, kind: Kind = .none, content: String? = nil, attachments: [Attachment] = [],
                            toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: String? = nil, name: String? = nil,
                            finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) -> Self {
        self.init(parent: parent, kind: kind, role: .assistant, content: content, attachments: attachments, toolCalls: toolCalls,
              toolCallID: toolCallID, runID: runID, name: name, finishReason: finishReason, metadata: metadata)
    }
    
    public static func user(parent: String? = nil, kind: Kind = .none, content: String? = nil, attachments: [Attachment] = [],
                            toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: String? = nil, name: String? = nil,
                            finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) -> Self {
        self.init(parent: parent, kind: kind, role: .user, content: content, attachments: attachments, toolCalls: toolCalls,
              toolCallID: toolCallID, runID: runID, name: name, finishReason: finishReason, metadata: metadata)
    }
    
    public static func tool(parent: String? = nil, kind: Kind = .none, content: String? = nil, attachments: [Attachment] = [],
                            toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, runID: String? = nil, name: String? = nil,
                            finishReason: FinishReason? = .stop, metadata: [String: String] = [:]) -> Self {
        self.init(parent: parent, kind: kind, role: .tool, content: content, attachments: attachments, toolCalls: toolCalls,
              toolCallID: toolCallID, runID: runID, name: name, finishReason: finishReason, metadata: metadata)
    }
}

extension Message {
    
    var visionImages: [Asset] {
        attachments
            .map { (attachment) -> Asset? in
                guard case .asset(let asset) = attachment else { return nil }
                return asset
            }
            .filter { $0?.kind == .image }
            .filter { $0?.noop == false }
            .compactMap { $0 }
    }
}
