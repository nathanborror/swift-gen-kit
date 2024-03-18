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
        var out = Anthropic.ChatRequest.Message(role: encode(role: message.role), content: [])
        
        let assets: [Asset] = message.visionImages
        
        // Prepare all the image assets attached to the message
        let contents = assets.map { (asset) -> Anthropic.ChatRequest.Message.Content? in
            switch asset.location {
            case .none:
                guard let data = asset.data else { return nil }
                return .init(type: .image, source: .init(type: .base64, mediaType: .png, data: data))
            default:
                return nil
            }
        }.compactMap { $0 }
        out.content += contents
        
        if let content = message.content {
            out.content.append(.init(type: .text, text: content))
        }
        return out
    }
    
    func encode(role: Message.Role) -> Anthropic.ChatRequest.Message.Role {
        switch role {
        case .system, .user: .user
        case .assistant, .tool: .assistant
        }
    }
}
