import Foundation
import MistralKit

extension MistralService {
    
    func encode(messages: [Message]) -> [MistralKit.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> MistralKit.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> MistralKit.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
