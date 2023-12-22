import Foundation
import SharedKit

public struct Message: Codable, Identifiable {
    public var id: String
    public var role: Role
    public var content: String?
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var created: Date
    public var modified: Date
    
    public enum Role: String, Codable {
        case system, assistant, user, tool
    }
    
    public enum FinishReason: Codable {
        case stop, length, toolCalls, contentFilter, cancelled
    }
    
    public enum Attachment: Codable {
        case none
    }
    
    public init(id: String = UUID().uuidString, role: Role, content: String? = nil, attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
        self.finishReason = finishReason
        self.created = .now
        self.modified = .now
    }
}

extension Message: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension Message {
    
    public func apply(_ message: Message) -> Message {
        var existing = self
        existing.content = existing.content?.apply(with: message.content)
        existing.finishReason = message.finishReason
        existing.modified = .now
        
        if let toolCalls = message.toolCalls {
            for toolCall in toolCalls {
                if toolCall.index < (existing.toolCalls?.count ?? 0) {
                    var existingToolCall = existing.toolCalls![toolCall.index]
                    existingToolCall.function.name = existingToolCall.function.name.apply(with: toolCall.function.name)
                    existingToolCall.function.arguments = existingToolCall.function.arguments.apply(with: toolCall.function.arguments)
                    existing.toolCalls![toolCall.index] = existingToolCall
                } else {
                    existing.toolCalls = [toolCall]
                }
            }
        }
        return existing
    }
}
