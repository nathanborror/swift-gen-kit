import Foundation
import Anthropic
import SharedKit

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
        
        // Collapse user images so there is only one before or after an assistant message.
        let collapsedMessages = messagesOut.reduce(into: [Anthropic.ChatRequest.Message]()) { result, message in
            if let lastMessage = result.last {
                if lastMessage.role == .user && message.role == .user {
                    // Combine the content of consecutive user messages
                    result[result.count - 1].content += message.content
                } else {
                    result.append(message)
                }
            } else {
                result.append(message)
            }
        }
        return (systemOut, collapsedMessages)
    }
    
    func encode(message: Message) -> Anthropic.ChatRequest.Message {
        var out = Anthropic.ChatRequest.Message(role: encode(role: message.role), content: [])
        
        // Prepare all the image assets attached to the message
        let assets: [Asset] = message.visionImages
        out.content += assets.map { (asset) -> Anthropic.ChatRequest.Message.Content? in
            switch asset.location {
            case .none:
                guard let data = asset.data else { return nil }
                return .init(type: .image, source: .init(type: .base64, mediaType: .png, data: data))
            default:
                return nil
            }
        }.compactMap { $0 }
        
        // Prepare tool calls
        if let toolCalls = message.toolCalls {
            for toolCall in toolCalls {
                if let data = toolCall.function.arguments.data(using: .utf8), let input = try? JSONDecoder().decode([String: AnyValue].self, from: data) {
                    let content = Anthropic.ChatRequest.Message.Content(
                        type: .tool_use,
                        id: toolCall.id,
                        name: toolCall.function.name,
                        input: input
                    )
                    out.content.append(content)
                }
            }
        }
        
        // Handle tool responses or append message content
        if message.role == .tool {
            out.content.append(.init(type: .tool_result, content: [.init(type: .text, text: message.content)], toolUseID: message.toolCallID))
        } else {
            if let text = message.content {
                out.content.append(.init(type: .text, text: text))
            }
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
