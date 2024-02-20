import Foundation
import GoogleGen

extension GoogleService {
    
    func encode(messages: [Message]) -> [Content] {
        messages
            .filter { $0.role != .system } // Gemini doesn't support context or system messages
            .map { encode(message: $0) }
            .filter { !$0.parts.isEmpty }
    }
    
    func encode(message: Message) -> Content {
        var parts = [Content.Part]()
        if let content = message.content {
            parts.append(.init(text: content))
        }
        return .init(role: encode(role: message.role), parts: parts)
    }
    
    func encode(role: Message.Role) -> String? {
        switch role {
        case .system, .assistant:
            return "model"
        case .user, .tool:
            return "user"
        }
    }
}
