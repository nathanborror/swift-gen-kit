import Foundation
import GoogleGen

extension GoogleService {
    
    func encode(messages: [Message]) -> [Content] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Content {
        .init(role: encode(role: message.role), parts: [.init(text: message.content ?? "")])
    }
    
    func encode(role: Message.Role) -> String? {
        switch role {
        case .assistant, .tool:
            return "model"
        case .user, .system:
            return "user"
        }
    }
}
