import Foundation
import SharedKit
import Llama

// MARK: - Chat Response

extension GenKit.Message {
    init(_ resp: Llama.ChatResponse) {
        self.init(
            role: .assistant,
            contents: [.init(resp.completion_message.content)].compactMap({$0}),
            toolCalls: resp.completion_message.tool_calls?.map { .init($0) },
            finishReason: .init(resp.completion_message.stop_reason)
        )
    }
}

extension GenKit.Message.Content {
    init?(_ content: Llama.ChatResponse.CompletionMessage.Content) {
        if let text = content.text {
            self = .text(text)
        } else if let reasoning = content.reasoning {
            self = .text(reasoning)
        } else if let answer = content.answer {
            self = .text(answer)
        } else {
            return nil
        }
    }
}

extension GenKit.ToolCall {
    init(_ toolCall: Llama.ToolCall) {
        self.init(
            id: toolCall.id,
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
}

extension GenKit.Message.FinishReason {
    init?(_ stop_reason: StopReason?) {
        switch stop_reason {
        case .stop:
            self = .stop
        case .length:
            self = .length
        case .tool_calls:
            self = .toolCalls
        default:
            return nil
        }
    }
}

// MARK: - Chat Response Stream

extension GenKit.Message {
    mutating func patch(with resp: Llama.ChatStreamResponse) {
        var contents = self.contents ?? []

        if ["start", "progress", "complete"].contains(resp.event.event_type)  {
            if case .text(let text) = contents.last, let delta = resp.event.delta.text {
                if let patched = GenKit.patch(string: text, with: delta) {
                    contents[contents.count-1] = .text(patched)
                }
            } else if let delta = resp.event.delta.text {
                contents.append(.text(delta))
            }
        }

        // TODO: Handle other possible event types

        self.contents = (contents.isEmpty) ? nil : contents

        // Patch remaining properties
        self.toolCalls = []
        self.finishReason = .init(resp.event.stop_reason)
        self.modified = .now
    }
}

// MARK: - Models

extension GenKit.Model {
    init(_ model: Llama.Model) {
        self.init(
            id: model.id,
            name: model.id,
            owner: model.owned_by
        )
    }
}
