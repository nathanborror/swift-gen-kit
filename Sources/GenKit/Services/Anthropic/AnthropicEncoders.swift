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
        
        // Handle tool responses or append message content
        if message.role == .tool {
            out.content.append(.init(type: .tool_result, content: [.init(type: .text, text: message.content)], toolUseID: message.toolCallID))
        } else {
            out.content.append(.init(type: .text, text: message.content))
        }
        return out
    }
    
    func encode(role: Message.Role) -> Anthropic.Role {
        switch role {
        case .system, .user, .tool: .user
        case .assistant: .assistant
        }
    }
    
    func encode(tools: Set<Tool>) -> [Anthropic.ChatRequest.Tool]? {
        guard !tools.isEmpty else { return nil }
        return tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Anthropic.ChatRequest.Tool {
        .init(
            name: tool.function.name,
            description: tool.function.description,
            inputSchema: tool.function.parameters
        )
    }
}
