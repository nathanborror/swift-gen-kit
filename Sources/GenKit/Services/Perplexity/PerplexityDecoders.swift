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
        return .init(
            role: decode(role: choice.message.role),
            content: choice.message.content,
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
    
    func decode(result: ChatStreamResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.delta.role),
            content: choice.delta.content,
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
    
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

    func decode(role: Perplexity.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        }
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
}
