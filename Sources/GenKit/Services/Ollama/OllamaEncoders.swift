import Foundation
import OllamaKit

extension OllamaService {
    
    func encode(messages: [Message]) -> [OllamaKit.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> OllamaKit.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> OllamaKit.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
