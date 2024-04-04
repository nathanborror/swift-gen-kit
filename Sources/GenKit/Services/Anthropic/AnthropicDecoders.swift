import Foundation
import OSLog
import Anthropic

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

extension AnthropicService {
    
    func decode(result: ChatResponse) -> Message {
        guard let content = result.content.first else {
            logger.warning("failed to decode content")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: result.role),
            content: content.text,
            finishReason: decode(finishReason: result.stopReason)
        )
    }
    
    func decode(result: ChatStreamResponse) -> Message {
        guard let delta = result.delta else {
            logger.warning("failed to decode delta")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: result.message?.role ?? .assistant),
            content: result.message?.content.first?.text ?? delta.text,
            finishReason: decode(finishReason: result.message?.stopReason ?? delta.stopReason)
        )
    }

    func decode(role: Anthropic.Role?) -> Message.Role {
        switch role {
        case .user: .user
        case .assistant, .none: .assistant
        }
    }

    func decode(finishReason: Anthropic.StopReason?) -> Message.FinishReason? {
        switch finishReason {
        case .end_turn:
            return .stop
        case .max_tokens:
            return .length
        case .stop_sequence:
            return .cancelled
        case .tool_use:
            return .toolCalls
        default:
            return .none
        }
    }
}
