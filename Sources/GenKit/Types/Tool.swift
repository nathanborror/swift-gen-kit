import Foundation
import SharedKit

public struct Tool: Codable {
    public var type: ToolType
    public var function: Function
    
    public enum ToolType: String, Codable {
        case function
    }
    
    public struct Function: Codable {
        public var name: String
        public var description: String
        public var parameters: JSONSchema
        
        public init(name: String, description: String, parameters: JSONSchema) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
    }
    
    public init(type: ToolType, function: Function) {
        self.type = type
        self.function = function
    }
}

extension Tool: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(function.name)
    }
    
    public static func == (lhs: Tool, rhs: Tool) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public struct ToolCall: Codable {
    public var id: String
    public var type: String
    public var function: FunctionCall
    public var index: Int
    
    public struct FunctionCall: Codable {
        public var name: String
        public var arguments: String
    }
}

extension ToolCall {
    
    public func apply(_ toolCall: ToolCall) -> ToolCall {
        var existing = self
        existing.function.name = existing.function.name.apply(with: toolCall.function.name)
        existing.function.arguments = existing.function.arguments.apply(with: toolCall.function.arguments)
        return existing
    }
}
