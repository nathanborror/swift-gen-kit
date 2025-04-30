import Foundation
import SharedKit
import Ollama

extension GenKit.Message {
    init(_ resp: Ollama.ChatResponse) {
        self.init(
            role: .init(resp.message?.role) ?? .assistant,
            content: resp.message?.content,
            toolCalls: resp.message?.tool_calls?.map { .init($0) },
            finishReason: .init(resp.done)
        )
    }

    mutating func patch(_ resp: Ollama.ChatResponse) {

        // Patch message content
        if case .text(let text) = contents?.last {
            if let patched = GenKit.patch(string: text, with: resp.message?.content) {
                self.contents = [.text(patched)]
            }
        } else if let text = resp.message?.content {
            self.contents = [.text(text)]
        }

        // Patch message tool calls
        if let toolCalls = resp.message?.tool_calls {
            if self.toolCalls == nil {
                self.toolCalls = []
            }
            self.toolCalls! += toolCalls.map { .init($0) }
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
            id: model.model,
            family: model.details?.family,
            name: model.name,
            owner: "ollama",
            contextWindow: nil,
            maxOutput: nil,
            trainingCutoff: nil
        )
    }
}
