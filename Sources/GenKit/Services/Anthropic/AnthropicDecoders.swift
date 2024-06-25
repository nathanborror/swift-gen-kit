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
    
    func decode(result: ChatStreamResponse, into message: Message) -> Message {
        var message = message
        switch result.type {
        case .ping:
            break
        case .error:
            break // nothing to do here
        case .message_start:
            if let msg = result.message {
                message.id = msg.id ?? message.id
                message.finishReason = decode(finishReason: msg.stopReason)
            }
        case .message_delta:
            break // nothing to do here
        case .message_stop:
            if message.toolCalls != nil {
                message.finishReason = .toolCalls
            } else {
                message.finishReason = .stop
            }
        case .content_block_start:
            if let contentBlock = result.contentBlock {
                switch contentBlock.type {
                case .text:
                    message.content = contentBlock.text
                case .tool_use:
                    var toolCall = ToolCall(function: .init(name: contentBlock.name ?? "", arguments: ""))
                    toolCall.id = contentBlock.id ?? toolCall.id
                    if message.toolCalls == nil {
                        message.toolCalls = []
                    }
                    message.toolCalls?.append(toolCall)
                default:
                    break
                }
            }
        case .content_block_delta:
            if let delta = result.delta {
                switch delta.type {
                case .text_delta:
                    message.content = message.content?.apply(with: delta.text)
                case .input_json_delta:
                    if var existing = message.toolCalls?.last {
                        existing.function.arguments = existing.function.arguments.apply(with: delta.partialJSON)
                        message.toolCalls![message.toolCalls!.count-1] = existing
                    }
                default:
                    break
                }
            }
        case .content_block_stop:
            break // nothing to do here
        }
        return message
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
