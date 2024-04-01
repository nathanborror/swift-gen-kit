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
            toolCalls: decode(toolCalls: choice.message.toolCalls),
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
            toolCalls: decode(toolCalls: choice.delta.toolCalls),
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
    
    func decode(toolCalls: [Mistral.Message.ToolCall]?) -> [ToolCall]? {
        guard let toolCalls else { return nil }
        return toolCalls.enumerated().map { index, toolCall in
            decode(toolCall: toolCall, index: index)
        }
    }
    
    func decode(toolCall: Mistral.Message.ToolCall, index: Int) -> ToolCall {
        .init(
            id: .id,
            type: "function",
            function: .init(
                name: toolCall.function.name ?? "",
                arguments: toolCall.function.arguments ?? ""
            ),
            index: index
        )
    }

    func decode(role: Mistral.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        case .tool: .tool
        }
    }

    func decode(finishReason: FinishReason?) -> Message.FinishReason? {
        guard let finishReason else { return .none }
        switch finishReason {
        case .stop: 
            return .stop
        case .length, .model_length:
            return .length
        case .tool_calls:
            return .toolCalls
        case .error:
            return .cancelled
        }
    }
}
