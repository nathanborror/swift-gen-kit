import Foundation
import SharedKit
import Ollama

extension GenKit.Message {
    init(_ resp: Ollama.ChatResponse) {
        self.init(
            role: .init(resp.message?.role) ?? .assistant,
            content: (resp.message?.content != nil) ? [.text(resp.message!.content)] : nil,
            toolCalls: resp.message?.tool_calls?.map { .init($0) },
            finishReason: .init(resp.done)
        )
    }

    mutating func patch(_ resp: Ollama.ChatResponse) {
        if case .text(let text) = content?.last {
            if let patched = GenKit.patch(string: text, with: resp.message?.content) {
                self.content = [.text(patched)]
            }
        }
        self.finishReason = .init(resp.done)
        self.modified = .now
    }
}

extension GenKit.Message.Role {
    init?(_ role: Ollama.Message.Role?) {
        guard let role else { return nil }
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

extension GenKit.Message.FinishReason {
    init?(_ done: Bool?) {
        guard let done, done else { return nil }
        self = .stop
    }
}

extension GenKit.ToolCall {
    init(_ toolCall: Ollama.ToolCall) {
        self.init(
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
}

extension GenKit.Model {
    init(_ model: Ollama.ModelResponse) {
        self.init(
            id: Model.ID(model.model),
            family: model.details?.family,
            name: model.name,
            owner: "ollama",
            contextWindow: nil,
            maxOutput: nil,
            trainingCutoff: nil
        )
    }
}
