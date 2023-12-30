import Foundation
import OpenAI

extension OpenAIService {
    
    func encode(messages: [Message]) -> [Chat] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Chat {
        .init(
            role: encode(role: message.role),
            content: message.content,
            name: message.name,
            toolCalls: message.toolCalls?.map { encode(toolCall: $0) },
            toolCallID: message.toolCallID
        )
    }
    
    func encode(role: Message.Role) -> Chat.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(toolCalls: [ToolCall]?) -> [Chat.ToolCall]? {
        toolCalls?.map { encode(toolCall: $0) }
    }
    
    func encode(toolCall: ToolCall) -> Chat.ToolCall {
        .init(
            id: toolCall.id,
            type: toolCall.type,
            function: encode(functionCall: toolCall.function),
            index: toolCall.index
        )
    }
    
    func encode(functionCall: ToolCall.FunctionCall) -> Chat.ToolCall.Function {
        .init(name: functionCall.name, arguments: functionCall.arguments)
    }
    
    func encode(tools: [Tool]?) -> [ChatQuery.Tool]? {
        guard let tools, !tools.isEmpty else { return nil }
        return tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> ChatQuery.Tool {
        .init(
            type: tool.type.rawValue,
            function: encode(function: tool.function)
        )
    }

    func encode(function: Tool.Function) -> ChatQuery.Tool.Function {
        .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters
        )
    }
    
    func encode(toolChoice: Tool?) -> ChatQuery.ToolChoice? {
        guard let toolChoice else { return nil }
        return .tool(
            .init(
                type: toolChoice.type.rawValue,
                function: encode(function: toolChoice.function)
            )
        )
    }
}
