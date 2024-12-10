import Foundation
import SharedKit
import Mistral

// MARK: - Chat Response

extension GenKit.Message {
    init?(_ resp: Mistral.ChatResponse) {
        guard let choice = resp.choices.first else { return nil }
        self.init(
            role: .assistant,
            content: choice.message.content != nil ? [.text(choice.message.content!)] : [],
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
    mutating func patch(with resp: Mistral.ChatStreamResponse) {
        guard let choice = resp.choices.first else { return }
        if case .text(let text) = content?.last, let delta = choice.delta.content {
            if let patched = GenKit.patch(string: text, with: delta) {
                self.content![self.content!.count-1] = .text(patched)
            }
        } else if let text = choice.delta.content {
            self.content?.append(.text(text))
        }
        self.toolCalls = choice.delta.tool_calls?.map { .init($0) }
        self.finishReason = .init(choice.finish_reason)
        self.modified = .now
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
