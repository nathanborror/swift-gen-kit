import Foundation
import OSLog
import Anthropic

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

extension AnthropicService {
    
    func decode(result: ChatResponse) -> Message {
        var message = Message(
            role: decode(role: result.role),
            finishReason: decode(finishReason: result.stopReason)
        )
        for content in result.content ?? [] {
            switch content.type {
            case .text, .text_delta:
                message.content = content.text
            case .tool_use:
                if message.toolCalls == nil {
                    message.toolCalls = []
                }
                let data = try? JSONEncoder().encode(content.input)
                message.toolCalls?.append(.init(
                    id: content.id ?? .id,
                    function: .init(
                        name: content.name ?? "",
                        arguments: (data != nil) ? String(data: data!, encoding: .utf8)! : ""
                    )
                ))
            case .input_json_delta:
                break
            case .none:
                break
            }
        }
        return message
    }
    
    func decode(result: ChatStreamResponse) -> Message {
        guard let delta = result.delta else {
            logger.warning("failed to decode delta")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: result.message?.role ?? .assistant),
            content: result.message?.content?.first?.text ?? delta.text,
            finishReason: decode(finishReason: result.message?.stopReason)
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
