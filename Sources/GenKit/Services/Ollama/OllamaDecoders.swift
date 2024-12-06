import Foundation
import SharedKit
import Ollama

extension OllamaService {
    
    func decode(result: ChatResponse, into message: Message? = nil) -> Message {
        if var message {
            if case .text(let text) = message.content?.last {
                if let patched = patch(string: text, with: result.message?.content) {
                    message.content = [.text(patched)]
                }
            }
            message.finishReason = decode(done: result.done)
            message.modified = .now
            return message
        }

        var message = Message(
            role: decode(role: result.message?.role),
            toolCalls: decode(toolCalls: result.message?.toolCalls),
            finishReason: decode(done: result.done)
        )
        if let content = result.message?.content {
            message.content = [.text(content)]
        }
        return message
    }
    
    func decode(toolCalls: [Ollama.ToolCall]?) -> [ToolCall]? {
        guard let toolCalls else { return nil }
        return toolCalls.map { decode(toolCall: $0) }
    }
    
    func decode(toolCall: Ollama.ToolCall) -> ToolCall {
        .init(
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }

    func decode(role: Ollama.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant: .assistant
        case .tool: .tool
        case .none: .assistant
        }
    }

    func decode(done: Bool?) -> Message.FinishReason? {
        guard let done else { return nil }
        return done ? .stop : nil
    }
    
    func decode(model: Ollama.ModelResponse) -> Model {
        .init(
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
