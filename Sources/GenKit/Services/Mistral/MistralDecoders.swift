import Foundation
import SharedKit
import Mistral

// MARK: - Chat Response

extension GenKit.Message {
    init?(_ resp: Mistral.ChatResponse) {
        guard let choice = resp.choices.first else { return nil }
        self.init(
            role: .assistant,
            content: choice.message.content,
            toolCalls: choice.message.tool_calls?.map { .init($0) },
            finishReason: .init(choice.finish_reason)
        )
    }
}

extension GenKit.ToolCall {
    init(_ toolCall: Mistral.ChatResponse.Choice.Message.ToolCall) {
        self.init(
            id: toolCall.id ?? "",
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
}

extension GenKit.Message.FinishReason {
    init?(_ reason: Mistral.ChatResponse.Choice.FinishReason?) {
        guard let reason else { return nil }
        switch reason {
        case .stop:
            self = .stop
        case .length:
            self = .length
        case .model_length:
            self = .length
        case .error:
            self = .error
        case .tool_calls:
            self = .toolCalls
        }
    }
}

// MARK: - Chat Response Stream

extension GenKit.Message {
    func patch(with resp: Mistral.ChatStreamResponse) -> Message {
        var existing = self

        // If there is no choice (rare) return existing message
        guard let choice = resp.choices.first else { return existing }

        // Get the last item in the contents array so it can be patched
        if var contents = existing.contents {
            if case .text(let text) = contents.last, let delta = choice.delta.content {
                if let patched = GenKit.patch(string: text, with: delta) {
                    contents[contents.count-1] = .text(patched)
                    existing.contents = contents
                }
            } else if let delta = choice.delta.content {
                contents.append(.text(delta))
                existing.contents = contents
            }
        }

        // Patch remaining properties
        existing.toolCalls = choice.delta.tool_calls?.map { .init($0) }
        existing.finishReason = .init(choice.finish_reason)
        existing.modified = .now
        return existing
    }
}



extension GenKit.ToolCall {
    init(_ toolCall: Mistral.ChatStreamResponse.Choice.Message.ToolCall) {
        self.init(
            id: toolCall.id ?? "",
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
}

extension GenKit.Message.FinishReason {
    init?(_ reason: Mistral.ChatStreamResponse.Choice.FinishReason?) {
        guard let reason else { return nil }
        switch reason {
        case .stop:
            self = .stop
        case .length:
            self = .length
        case .model_length:
            self = .length
        case .error:
            self = .error
        case .tool_calls:
            self = .toolCalls
        }
    }
}

// MARK: - Models

extension GenKit.Model {
    init(_ model: Mistral.ModelsResponse.Model) {
        self.init(
            id: Model.ID(model.id),
            name: model.name,
            owner: model.owned_by ?? "mistral",
            contextWindow: model.max_context_length,
            maxOutput: model.max_context_length,
            trainingCutoff: nil
        )
    }
}
