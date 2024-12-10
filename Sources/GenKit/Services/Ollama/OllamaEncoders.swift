import Foundation
import Ollama

extension Ollama.Message {
    init(_ message: GenKit.Message) {
        self.init(
            role: .init(message.role),
            content: Self.encode(message.content),
            images: Self.encode(images: message.content)
        )
    }

    static func encode(_ content: [Message.Content]?) -> String {
        content?.compactMap {
            switch $0 {
            case .text(let text):
                return text
            default:
                return ""
            }
        }.joined() ?? ""
    }

    static func encode(images content: [Message.Content]?) -> [Data]? {
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

extension Ollama.Message.Role {
    init(_ role: GenKit.Message.Role) {
        switch role {
        case .system:
            self = .system
        case .user:
            self = .user
        case .assistant:
            self = .assistant
        case .tool:
            self = .tool
        }
    }
}

extension Ollama.Tool {
    init(_ tool: GenKit.Tool) {
        self.init(
            type: "function",
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
}
