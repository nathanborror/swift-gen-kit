import Foundation
import OpenAI
import SharedKit

// MARK: - Chat Response

extension GenKit.Message {
    init?(_ resp: OpenAI.ChatResponse) {
        guard let choice = resp.choices.first else { return nil }
        self.init(
            role: .init(choice.message.role),
            content: [.init(choice.message.content)].compactMap { $0 },
            toolCalls: choice.message.tool_calls?.map { .init($0) },
            finishReason: .init(choice.finish_reason)
        )
    }
}

extension GenKit.Message.Role {
    init(_ role: String) {
        switch role {
        case "system":
            self = .system
        case "user":
            self = .user
        case "assistant":
            self = .assistant
        case "tool":
            self = .tool
        default:
            self = .assistant
        }
    }
}

extension GenKit.Message.Content {
    init?(_ content: String?) {
        guard let content else { return nil }
        self = .text(content)
    }
}

extension GenKit.Message.FinishReason {
    init?(_ reason: String?) {
        switch reason {
        case "stop":
            self = .stop
        case "length":
            self = .length
        case "tool_calls":
            self = .toolCalls
        case "content_filter":
            self = .contentFilter
        default:
            return nil
        }
    }
}

extension GenKit.ToolCall {
    init(_ resp: OpenAI.ChatResponse.Choice.Message.ToolCall) {
        self.init(
            id: resp.id ?? "",
            type: resp.type ?? "function",
            function: .init(
                name: resp.function.name ?? "",
                arguments: resp.function.arguments
            )
        )
    }
}

// MARK: - Chat Response Stream

extension GenKit.Message {
    mutating func patch(with resp: OpenAI.ChatStreamResponse) {
        guard let choice = resp.choices.first else { return }

        if case .text(let text) = content?.last {
            if let patched = GenKit.patch(string: text, with: choice.delta.content) {
                content = [.text(patched)]
            }
        } else if let text = choice.delta.content {
            content = [.text(text)]
        }
        finishReason = .init(choice.finish_reason)
        modified = .now

        // Convoluted way to add new tool calls and patch the last tool call being streamed in.
        if let toolCalls = choice.delta.tool_calls {
            if self.toolCalls == nil {
                self.toolCalls = []
            }
            for toolCall in toolCalls {
                if toolCall.id == nil, var existing = self.toolCalls?.first(where: { $0.index == toolCall.index }) {
                    existing.function.arguments = GenKit.patch(string: existing.function.arguments, with: toolCall.function.arguments) ?? ""
                    self.toolCalls![existing.index!] = existing
                } else {
                    self.toolCalls?.append(.init(toolCall))
                }
            }
        }
    }
}

// MARK: - Model

extension GenKit.Model {
    init(_ model: OpenAI.Model) {
        self.init(
            id: .init(model.id),
            name: model.id,
            owner: model.owned_by
        )
    }
}
