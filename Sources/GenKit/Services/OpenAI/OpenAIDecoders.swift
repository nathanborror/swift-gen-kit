import Foundation
import OpenAI

extension OpenAIService {
    
    func decode(result: ChatStreamResult) -> Message {
        let choice = result.choices.first
        return .init(
            id: result.id,
            role: .assistant,
            content: choice?.delta.content,
            toolCalls: choice?.delta.toolCalls?.map { decode(toolCall: $0) },
            finishReason: decode(finishReason: choice?.finishReason)
        )
    }

    func decode(result: ChatResult) -> Message {
        let choice = result.choices.first
        let message = choice?.message
        
        return .init(
            id: result.id,
            role: decode(role: message?.role ?? .assistant),
            content: message?.content,
            toolCalls: message?.toolCalls?.map { decode(toolCall: $0) },
            toolCallID: message?.toolCallID,
            name: message?.name,
            finishReason: decode(finishReason: choice?.finishReason))
    }

    func decode(role: Chat.Role) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant: .assistant
        case .tool: .tool
        }
    }

    func decode(finishReason: String?) -> Message.FinishReason? {
        switch finishReason {
        case "stop": .stop
        case "length": .length
        case "tool_calls": .toolCalls
        case "content_filter": .contentFilter
        default: nil
        }
    }

    func decode(toolCall: Chat.ToolCall) -> ToolCall {
        .init(
            id: toolCall.id ?? "",
            type: toolCall.type ?? "",
            function: .init(
                name: toolCall.function.name ?? "",
                arguments: toolCall.function.arguments ?? ""
            ),
            index: toolCall.index ?? 0
        )
    }
}
