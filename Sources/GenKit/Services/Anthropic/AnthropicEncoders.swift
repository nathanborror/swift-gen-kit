import Foundation
import Anthropic

extension AnthropicService {
    
    func encode(messages: [Message]) -> [Anthropic.ChatRequest.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Anthropic.ChatRequest.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> Anthropic.ChatRequest.Message.Role {
        switch role {
        case .system, .user: .user
        case .assistant, .tool: .assistant
        }
    }
}
