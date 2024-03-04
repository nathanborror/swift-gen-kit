import Foundation
import Anthropic

extension AnthropicService {
    
    func encode(messages: [Message]) -> (String?, [Anthropic.ChatRequest.Message]) {
        var systemOut: String? = nil
        var messagesOut = [Anthropic.ChatRequest.Message]()
        
        for i in messages.indices {
            if i == 0 && messages[i].role == .system {
                systemOut = messages[i].content
            } else {
                let message = encode(message: messages[i])
                messagesOut.append(message)
            }
        }
        return (systemOut, messagesOut)
    }
    
    func encode(message: Message) -> Anthropic.ChatRequest.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> Anthropic.ChatRequest.Message.Role {
        switch role {
        case .system, .user: .user
        case .assistant, .tool: .assistant
        }
    }
}
