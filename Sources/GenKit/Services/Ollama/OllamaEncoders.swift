import Foundation
import Ollama

extension OllamaService {
    
    func encode(messages: [Message]) -> [Ollama.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Ollama.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> Ollama.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
