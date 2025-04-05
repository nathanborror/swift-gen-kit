import Foundation
import Ollama

extension Ollama.Message {
    init(_ message: GenKit.Message) {
        self.init(
            role: .init(message.role),
            content: Self.encode(message.contents),
            images: Self.encode(images: message.contents)
        )
    }

    static func encode(_ contents: [Message.Content]?) -> String {
        contents?.compactMap {
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
            case .image(let image):
                if let data = try? Data(contentsOf: image.url) {
                    return data
                }
            default:
                return nil
            }
            return nil
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
