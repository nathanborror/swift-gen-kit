import Foundation
import SharedKit
import JSONSchema

// Tools

public struct Tool: Codable, Hashable, Sendable {
    public var type: Kind
    public var function: Function
    
    public enum Kind: String, Codable, Hashable, Sendable {
        case function
    }

    public struct Function: Codable, Hashable, Sendable {
        public var name: String
        public var description: String
        public var parameters: JSONSchema
        
        public init(name: String, description: String, parameters: JSONSchema) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
    }
    
    public init(type: Kind = .function, function: Function) {
        self.type = type
        self.function = function
    }
}

// Tool Calls

public struct ToolCall: Identifiable, Codable, Hashable, Sendable {
    public var index: Int?
    public var id: String
    public var type: String
    public var function: FunctionCall
    
    public struct FunctionCall: Codable, Hashable, Sendable {
        public var name: String
        public var arguments: String
        
        public init(name: String, arguments: String) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(index: Int? = nil, id: String = .id, type: String = "function", function: FunctionCall) {
        self.index = index
        self.id = id
        self.type = type
        self.function = function
    }
    
    public func apply(_ toolCall: ToolCall) -> ToolCall {
        var existing = self
        
        // Name should never be a fragment so we shouldn't 'apply' it like other strings.
        if existing.function.name.isEmpty {
            existing.function.name = toolCall.function.name
        }
        
        existing.function.arguments = existing.function.arguments.apply(with: toolCall.function.arguments)
        return existing
    }
}

public struct ToolCallResponse: Codable, Hashable, Sendable {
    public var messages: [Message]
    public var shouldContinue: Bool
    
    public init(messages: [Message], shouldContinue: Bool) {
        self.messages = messages
        self.shouldContinue = shouldContinue
    }
}
