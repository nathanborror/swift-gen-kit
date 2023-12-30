import Foundation
import OllamaKit

extension OllamaService {
    
    func decode(result: ChatResponse) -> Message {
        return .init(
            role: decode(role: result.message?.role),
            content: result.message?.content,
            finishReason: decode(done: result.done)
        )
    }

    func decode(role: OllamaKit.Message.Role?) -> Message.Role {
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
