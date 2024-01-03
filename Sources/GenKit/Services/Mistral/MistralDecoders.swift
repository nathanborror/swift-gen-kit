import Foundation
import OSLog
import MistralKit

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
            finishReason: decode(finishReason: choice.finishReason)
        )
    }

    func decode(role: MistralKit.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        }
    }

    func decode(finishReason: ChatResponse.Choice.FinishReason) -> Message.FinishReason? {
        switch finishReason {
        case .stop: .stop
        case .length, .model_length: .length
        }
    }
}
