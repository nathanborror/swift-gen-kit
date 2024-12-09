import Foundation
import Anthropic
import SharedKit

// MARK: - Chat Response

extension GenKit.Message {
    init(_ resp: Anthropic.ChatResponse) {
        self.init(
            role: .init(resp.role) ?? .assistant,
            content: resp.content?.compactMap { .init($0) },
            toolCalls: resp.content?.compactMap { .init($0) },
            finishReason: .init(resp.stop_reason)
        )
    }
}

extension GenKit.Message.Role {
    init?(_ role: Anthropic.ChatResponse.Role?) {
        guard let role else { return nil }
        switch role {
        case .assistant:
            self = .assistant
        case .user:
            self = .user
        }
    }
}

extension GenKit.Message.Content {
    init?(_ content: Anthropic.ChatResponse.Content) {
        switch content.type {
        case .text, .text_delta:
            if let text = content.text {
                self = .text(text)
            } else {
                return nil
            }
        case .tool_use, .input_json_delta, .none:
            return nil
        }
    }
}

extension GenKit.Message.FinishReason {
    init?(_ reason: Anthropic.ChatResponse.StopReason?) {
        guard let reason else { return nil }
        switch reason {
        case .end_turn:
            self = .stop
        case .max_tokens:
            self = .length
        case .stop_sequence:
            self = .stop
        case .tool_use:
            self = .toolCalls
        }
    }
}

extension GenKit.ToolCall {
    init?(_ content: Anthropic.ChatResponse.Content) {
        switch content.type {
        case .tool_use:
            let data = try? JSONEncoder().encode(content.input)
            let arguments = (data != nil) ? String(data: data!, encoding: .utf8)! : ""
            self.init(
                id: content.id ?? .id,
                function: .init(
                    name: content.name ?? "",
                    arguments: arguments
                )
            )
        case .text, .text_delta, .input_json_delta, .none:
            return nil
        }
    }
}

// MARK: - Chat Response Stream

extension GenKit.Message {
    mutating func patch(with resp: ChatResponseStream) {
        switch resp.type {
        case .ping, .error, .message_delta, .content_block_stop:
            return
        case .message_start:
            if let message = resp.message {
                self.id = (message.id != nil) ? Message.ID(message.id!) : self.id
                self.finishReason = .init(message.stop_reason)
            }
        case .message_stop:
            self.finishReason = (self.toolCalls != nil) ? .toolCalls : .stop
        case .content_block_start:
            print("do something")
        case .content_block_delta:
            print("do something")
        }
        self.modified = .now
    }
}

//        case .content_block_start:
//            if let contentBlock = result.contentBlock {
//                switch contentBlock.type {
//                case .text:
//                    if let text = contentBlock.text {
//                        message.content = [.text(text)]
//                    }
//                case .tool_use:
//                    var toolCall = ToolCall(function: .init(name: contentBlock.name ?? "", arguments: ""))
//                    toolCall.id = contentBlock.id ?? toolCall.id
//                    if message.toolCalls == nil {
//                        message.toolCalls = []
//                    }
//                    message.toolCalls?.append(toolCall)
//                default:
//                    break
//                }
//            }
//        case .content_block_delta:
//            if let delta = result.delta {
//                switch delta.type {
//                case .text_delta:
//                    message.content = patch(string: message.content, with: delta.text)
//                case .input_json_delta:
//                    if var existing = message.toolCalls?.last {
//                        existing.function.arguments = patch(string: existing.function.arguments, with: delta.partialJSON) ?? ""
//                        message.toolCalls![message.toolCalls!.count-1] = existing
//                    }
//                default:
//                    break
//                }
//            }
