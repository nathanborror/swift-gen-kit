import Foundation
import Anthropic
import SharedKit

extension Anthropic.ChatRequest.Message {
    init(_ message: GenKit.Message) {
        self.init(
            role: .init(message.role),
            content: message.content?.compactMap { .init($0) } ??
                message.toolCalls?.compactMap { .init($0) } ??
                [.init(message)].compactMap { $0 }
        )
    }
}

extension Anthropic.ChatRequest.Message.Content {
    init?(_ content: GenKit.Message.Content) {
        switch content {
        case .text(let text):
            self.init(
                type: .text,
                text: text
            )
        // TODO: Remove hard-coded media type
        case .image(let data, let format):
            self.init(
                type: .image,
                source: .init(
                    type: .base64,
                    media_type: .init(rawValue: format.rawValue) ?? .png,
                    data: data
                )
            )
        case .audio:
            return nil
        }
    }

    init?(_ toolCall: GenKit.ToolCall?) {
        guard let toolCall else { return nil }
        guard let data = toolCall.function.arguments.data(using: .utf8) else { return nil }
        guard let input = try? JSONDecoder().decode([String: AnyValue].self, from: data) else { return nil }
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
            content: toolMessage.content?.compactMap { .init($0) }
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
