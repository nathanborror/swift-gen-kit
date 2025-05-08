import Foundation
import Llama

extension Llama.ChatRequest.Message {
    init(_ message: GenKit.Message) {
        let content = message.contents?.map({ Llama.ChatRequest.Message.Content($0) }).compactMap({$0})
        self.init(
            role: .init(message.role),
            content: content ?? [],
            tool_call_id: message.toolCallID,
            tool_calls: message.toolCalls?.map { .init($0) },
            stop_reason: .init(message.finishReason)
        )
    }
}

extension Llama.ChatRequest.Message.Content {
    init?(_ content: GenKit.Message.Content) {
        switch content {
        case .text(let text):
            self = .init(text: text)
            return
        case .image(let image):
            if let data = try? Data(contentsOf: image.url) {
                self = .init(image: "data:image/\(image.format);base64,\(data.base64EncodedString())")
                return
            }
        case .audio, .json, .file:
            return nil
        }
        return nil
    }
}

extension Llama.ChatRequest.Message.Role {
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

extension Llama.Tool {
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

extension Llama.ToolChoice {
    init?(_ tool: GenKit.Tool?) {
        guard let tool else { return nil }
        self.init(
            type: "function",
            function: .init(name: tool.function.name)
        )
    }
}

extension Llama.ToolCall {
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

extension Llama.StopReason {
    init?(_ finishReason: Message.FinishReason?) {
        switch finishReason {
        case .stop:
            self = .stop
        case .length:
            self = .length
        case .toolCalls:
            self = .tool_calls
        default:
            return nil
        }
    }
}
