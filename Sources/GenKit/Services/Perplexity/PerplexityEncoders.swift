import Foundation
import PerplexityKit

extension PerplexityService {
    
    func encode(messages: [Message]) -> [PerplexityKit.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> PerplexityKit.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> PerplexityKit.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
