import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

extension PerplexityService {
    
    func decode(result: ChatResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        var message = Message(
            role: decode(role: choice.message.role),
            finishReason: decode(finishReason: choice.finishReason)
        )
        if case .text(let text) = message.contents?.last {
            if let patched = patch(string: text, with: choice.message.content) {
                message.contents = [.text(patched)]
            }
        }
        return message
    }
    
    func decode(result: ChatStreamResponse, into message: Message) -> Message {
        var message = message
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        if case .text(let text) = message.contents?.last {
            if let patched = patch(string: text, with: choice.delta.content) {
                message.contents = [.text(patched)]
            }
        }
        message.finishReason = decode(finishReason: choice.finishReason)
        message.modified = .now
        return message
    }

    func decode(role: Perplexity.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        }
    }

    func decode(content: String, into message: Message) -> [Message.Content] {
        guard message.role == .assistant else { return [] }
        guard
            let existing = message.contents, content.count > 0,
            case .text(let existingText) = existing.last,
            let patched = patch(string: existingText, with: content)
        else {
            return [.text(content)]
        }
        return [.text(patched)]
    }

    func decode(finishReason: FinishReason?) -> Message.FinishReason? {
        guard let finishReason else { return .none }
        switch finishReason {
        case .stop:
            return .stop
        case .length, .model_length:
            return .length
        }
    }

    // Tools

    func decode(tool: Tool, result: ChatResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.message.role),
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.message.content))
            ],
            finishReason: decode(finishReason: choice.finishReason)
        )
    }

    func decode(tool: Tool, result: ChatStreamResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.delta.role),
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.message.content))
            ],
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
}
