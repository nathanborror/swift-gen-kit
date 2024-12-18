import Foundation
import Mistral

extension Mistral.ChatRequest.Message {
    init(_ message: GenKit.Message) {
        self.init(
            content: message.contents?.map { .init($0) },
            tool_calls: nil,
            prefix: nil,
            role: .init(message.role)
        )
    }
}

extension Mistral.ChatRequest.Message.Content {
    init(_ content: GenKit.Message.Content) {
        switch content {
        case .text(let text):
            self.init(type: .text, text: text)
        case .image(let data, let format):
            self.init(type: .image_url, image_url: .init(url: "data:image/\(format);base64,\(data.base64EncodedString())"))
        default:
            fatalError("Unknown message content type")
        }
    }
}

extension Mistral.ChatRequest.Message.Role {
    init(_ role: GenKit.Message.Role) {
        switch role {
        case .system:
            self = .system
        case .assistant:
            self = .assistant
        case .user:
            self = .user
        case .tool:
            self = .tool
        }
    }
}

extension Mistral.ChatRequest.Tool {
    init(_ tool: GenKit.Tool) {
        self.init(
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
}

extension Mistral.ChatRequest.ToolChoice {
    init?(_ tool: GenKit.Tool?) {
        guard let tool else { return nil }
        self = .tool(.init(function: .init(name: tool.function.name)))
    }
}

extension Mistral.ChatRequest.Message.ToolCall {
    init(_ toolCall: GenKit.ToolCall) {
        self.init(
            id: toolCall.id,
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
}
