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
    
    func decode(result: ChatStreamResponse, into message: Message) -> Message {
        var message = message
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        
        message.content = patch(string: message.content, with: choice.delta.content)
        message.finishReason = decode(finishReason: choice.finishReason)
        message.modified = .now
        message.toolCalls = decode(toolCalls: choice.delta.toolCalls)
        
        return message
    }
    
    func decode(toolCalls: [Mistral.Message.ToolCall]?) -> [ToolCall]? {
        toolCalls?.map { decode(toolCall: $0) }
    }
    
    func decode(toolCall: Mistral.Message.ToolCall) -> ToolCall {
        .init(
            id: .id,
            type: "function",
            function: .init(
                name: toolCall.function.name ?? "",
                arguments: toolCall.function.arguments ?? ""
            )
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
