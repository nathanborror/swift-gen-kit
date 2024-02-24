import Foundation
import OSLog
import SharedKit
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

extension MistralService {
    
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
            role: decode(role: choice.delta.role ?? .assistant),
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
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.message.content ?? "{}"), index: 0)
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
            role: decode(role: choice.delta.role ?? .assistant),
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.delta.content ?? "{}"), index: 0)
            ],
            finishReason: decode(finishReason: choice.finishReason)
        )
    }

    func decode(role: Mistral.Message.Role?) -> Message.Role {
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
