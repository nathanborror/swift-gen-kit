import Foundation
import Mistral

extension MistralService {
    
    func encode(messages: [Message]) -> [Mistral.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Mistral.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? "",
            toolCalls: encode(toolCalls: message.toolCalls),
            toolCallID: message.toolCallID
        )
    }
    
    func encode(role: Message.Role) -> Mistral.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(tools: Set<Tool>) -> [Mistral.Tool] {
        tools.map { encode(tool: $0) }
    }

    func encode(tool: Tool) -> Mistral.Tool {
        .init(
            type: tool.type.rawValue,
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
    
    func encode(toolCalls: [ToolCall]?) -> [Mistral.Message.ToolCall]? {
        guard let toolCalls else { return nil }
        return toolCalls.map { encode(toolCall: $0) }
    }
    
    func encode(toolCall: ToolCall) -> Mistral.Message.ToolCall {
        .init(
            id: toolCall.id,
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    func encode(toolChoice: Tool?) -> ChatRequest.ToolChoice {
        if toolChoice != nil {
            return .any
        }
        return .auto
    }
}
