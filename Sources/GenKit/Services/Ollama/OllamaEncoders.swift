import Foundation
import Ollama

extension OllamaService {
    
    func encode(messages: [Message]) -> [Ollama.Message] {
        if messages.count == 1 { // When there's just one message it has to be from the user.
            var message = messages[0]
            message.role = .user // force this to be a user message
            return [encode(message: message)]
        }
        return messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Ollama.Message {
        .init(
            role: encode(role: message.role),
            content: encode(content: message.content) ?? "",
            images: encode(images: message.content)
        )
    }

    func encode(content: [Message.Content]?) -> String? {
        content?.compactMap {
            switch $0 {
            case .text(let text):
                return text
            default:
                return nil
            }
        }.joined()
    }

    func encode(tools: [Tool]) -> [Ollama.Tool] {
        tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Ollama.Tool {
        let jsonData = try? JSONEncoder().encode(tool.function.parameters)
        let json = String(data: jsonData!, encoding: .utf8)!
        
        return .init(
            type: "function",
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
    
    func encode(role: Message.Role) -> Ollama.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(images content: [Message.Content]?) -> [Data]? {
        content?.compactMap {
            switch $0 {
            case .image(let data):
                return data
            default:
                return nil
            }
        }
    }
}
