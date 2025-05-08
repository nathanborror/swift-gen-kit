import Foundation
import Anthropic
import JSONSchema

extension Anthropic.ChatRequest.Message {
    init(_ message: GenKit.Message) {
        self.init(
            role: .init(message.role),
            content: message.contents?.compactMap { .init($0) } ?? message.toolCalls?.compactMap { .init($0) } ?? [.init(message)].compactMap { $0 }
        )
    }
}

extension Anthropic.ChatRequest.Message.Content {
    init?(_ content: GenKit.Message.Content) {
        switch content {
        case .text(let text):
            self.init(type: .text, text: text)
        case .image(let image):
            if let data = try? Data(contentsOf: image.url) {
                self.init(
                    type: .image,
                    source: .init(
                        type: .base64,
                        media_type: .init(rawValue: image.format.rawValue) ?? .png,
                        data: data
                    )
                )
            } else {
                return nil
            }
        case .audio:
            return nil
        case .json(let json):
            self.init(type: .text, text: json.object)
        case .file(let file):
            guard
                let data = try? Data(contentsOf: file.url),
                let content = String(data: data, encoding: .utf8)
            else { return nil }

            self.init(type: .text, text: """
                ```\(file.type) \(file.url.lastPathComponent)
                \(content)
                ```
                """)
        }
    }

    init?(_ toolCall: GenKit.ToolCall?) {
        guard let toolCall else { return nil }
        guard let data = toolCall.function.arguments.data(using: .utf8) else { return nil }
        guard let input = try? JSONDecoder().decode([String: JSONValue].self, from: data) else { return nil }
        self.init(
            type: .tool_use,
            id: toolCall.id,
            name: toolCall.function.name,
            input: input
        )
    }

    init?(_ toolMessage: GenKit.Message) {
        guard toolMessage.role == .tool else { return nil }
        self.init(
            type: .tool_result,
            tool_use_id: toolMessage.toolCallID,
            content: toolMessage.contents?.compactMap { .init($0) }
        )
    }
}

extension Anthropic.ChatRequest.Message.Role {
    init(_ role: GenKit.Message.Role) {
        switch role {
        case .system, .user, .tool:
            self = .user
        case .assistant:
            self = .assistant
        }
    }
}

extension Anthropic.ChatRequest.Tool {
    init(_ tool: GenKit.Tool) {
        self.init(
            name: tool.function.name,
            description: tool.function.description,
            input_schema: tool.function.parameters
        )
    }
}

extension Anthropic.ChatRequest.ToolChoice {
    init(_ tool: GenKit.Tool?) {
        guard let tool else {
            self.init(type: .auto)
            return
        }
        self.init(
            type: .tool,
            name: tool.function.name
        )
    }
}
