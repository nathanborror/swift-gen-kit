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
        case .tool: .assistant
        }
    }
}
