import Foundation
import Mistral

extension MistralService {
    
    func encode(messages: [Message]) -> [Mistral.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Mistral.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
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
    
    func encode(toolChoice: Tool?) -> ChatRequest.ToolChoice {
        if toolChoice != nil {
            return .any
        }
        return .auto
    }
}
