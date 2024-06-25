import Foundation
import SharedKit
import Ollama

extension OllamaService {
    
    func decode(result: ChatResponse, into message: Message? = nil) -> Message {
        if var message {
            message.content = patch(string: message.content, with: result.message?.content)
            message.finishReason = decode(done: result.done)
            message.modified = .now
            return message
        } else {
            return .init(
                role: decode(role: result.message?.role),
                content: result.message?.content,
                finishReason: decode(done: result.done)
            )
        }
    }
    
    func decode(tool: Tool, result: ChatResponse, into message: Message? = nil) -> Message {
        guard let arguments = result.message?.content else {
            return decode(result: result, into: message)
        }
        if var message {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            message.toolCalls?.append(.init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: arguments)))
            message.finishReason = decode(done: result.done)
            message.modified = .now
            return message
        } else {
            return .init(
                role: decode(role: result.message?.role),
                toolCalls: [
                    .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: arguments))
                ],
                finishReason: decode(done: result.done)
            )
        }
    }

    func decode(role: Ollama.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        }
    }

    func decode(done: Bool?) -> Message.FinishReason? {
        guard let done else { return nil }
        return done ? .stop : nil
    }
}
