import Foundation
import SharedKit
import Ollama

extension OllamaService {
    
    func decode(result: ChatResponse) -> Message {
        return .init(
            role: decode(role: result.message?.role),
            content: result.message?.content,
            finishReason: decode(done: result.done)
        )
    }
    
    func decode(tool: Tool, result: ChatResponse) -> Message {
        guard let arguments = result.message?.content else {
            return decode(result: result)
        }
        return .init(
            role: decode(role: result.message?.role),
            content: nil,
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: arguments), index: 0)
            ],
            finishReason: decode(done: result.done)
        )
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
