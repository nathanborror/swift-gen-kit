import Foundation
import SharedKit
import JSONSchema

// Tools

public struct Tool: Codable, Hashable, Sendable {
    public var type: Kind
    public var function: Function?
    public var custom: Custom?

    public enum Kind: String, Codable, Hashable, Sendable {
        case function
        case custom
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

    public struct Custom: Codable, Hashable, Sendable {
        public var name: String
        public var description: String?
        public var format: Format?

        public struct Format: Codable, Hashable, Sendable {
            public var type: String
            public var grammar: Grammar?

            public struct Grammar: Codable, Hashable, Sendable {
                public var definition: String
                public var syntax: String

                public init(definition: String, syntax: String) {
                    self.definition = definition
                    self.syntax = syntax
                }
            }

            public init(type: String, grammar: Grammar? = nil) {
                self.type = type
                self.grammar = grammar
            }
        }

        public init(name: String, description: String? = nil, format: Format? = nil) {
            self.name = name
            self.description = description
            self.format = format
        }
    }

    public init(function: Function) {
        self.type = .function
        self.function = function
        self.custom = nil
    }

    public init(custom: Custom) {
        self.type = .custom
        self.function = nil
        self.custom = custom
    }
}

// Tool Calls

public struct ToolCall: Identifiable, Codable, Hashable, Sendable {
    public var index: Int?
    public var id: String
    public var type: String
    public var function: Function?
    public var custom: Custom?

    public struct Function: Codable, Hashable, Sendable {
        public var name: String
        public var arguments: String
        
        public init(name: String, arguments: String) {
            self.name = name
            self.arguments = arguments
        }
    }

    public struct Custom: Codable, Hashable, Sendable {
        public var name: String
        public var input: String

        public init(name: String, input: String) {
            self.name = name
            self.input = input
        }
    }

    public init(index: Int? = nil, id: String = .id, type: String, function: Function?, custom: Custom?) {
        self.index = index
        self.id = id
        self.type = type
        self.function = function
    }
    
    public func apply(_ toolCall: ToolCall) -> ToolCall {
        var existing = self
        if let function = existing.function {
            // Name should never be a fragment so we shouldn't 'apply' it like other strings.
            if function.name.isEmpty, let name = toolCall.function?.name {
                existing.function?.name = name
            }
            if let existingFunction = existing.function {
                existing.function?.arguments = existingFunction.arguments.apply(with: function.arguments)
            }
        }
        if let custom = existing.custom {
            // Name should never be a fragment so we shouldn't 'apply' it like other strings.
            if custom.name.isEmpty, let name = toolCall.custom?.name {
                existing.custom?.name = name
            }
            if let existingCustom = existing.custom {
                existing.custom?.input = existingCustom.input.apply(with: custom.input)
            }
        }
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
