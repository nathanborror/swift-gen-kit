import Foundation
import Perplexity

extension PerplexityService {
    
    func encode(messages: [Message]) -> [Perplexity.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Perplexity.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> Perplexity.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
