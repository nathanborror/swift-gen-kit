import Foundation
import OpenAI
import SharedKit

extension OpenAIService {
    
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
    
    func decode(result: ChatStreamResult, into message: Message) -> Message {
        var message = message
        let choice = result.choices.first
        
        message.content = patch(string: message.content, with: choice?.delta.content)
        message.finishReason = decode(finishReason: choice?.finishReason)
        message.modified = .now
        
        // Convoluted way to add new tool calls and patch the last tool call being streamed in.
        if let toolCalls = choice?.delta.toolCalls {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            for toolCall in toolCalls {
                if toolCall.id == nil {
                    if var existing = message.toolCalls?.last {
                        existing.function.arguments = patch(string: existing.function.arguments, with: toolCall.function.arguments) ?? ""
                        message.toolCalls![message.toolCalls!.count-1] = existing
                    }
                } else {
                    let newToolCall = decode(toolCall: toolCall)
                    message.toolCalls?.append(newToolCall)
                }
            }
        }
        return message
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
            )
        )
    }
}
