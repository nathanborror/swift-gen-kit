import Foundation
import Anthropic
import SharedKit

extension AnthropicService {
    
    // Extract all system messages and combine into one because Anthropic accepts a single system prompt as part of the
    // chat request instead of system messages. Combine multiple user messages so we always have alternating user and
    // assistant messages.
    func encode(messages: [Message]) -> (String?, [Anthropic.ChatRequestMessage]) {
        let system = messages
            .filter { $0.role == .system }
            .map { $0.content }
            .compactMap { $0 }
            .joined(separator: "\n\n")
        
        let messagesFiltered = messages
            .filter { $0.role != .system }
            .map { encode(message: $0) }
        
        let messagesCleaned = messagesFiltered.reduce(into: [Anthropic.ChatRequestMessage]()) { result, message in
            if let lastMessage = result.last {
                if lastMessage.role == .user && message.role == .user {
                    result[result.count - 1].content += message.content
                } else {
                    result.append(message)
                }
            } else {
                result.append(message)
            }
        }
        return (system, messagesCleaned)
    }
    
    func encode(message: Message) -> Anthropic.ChatRequestMessage {
        var out = Anthropic.ChatRequestMessage(role: encode(role: message.role), content: [])
        
        // Prepare all the image assets attached to the message
        let assets: [Asset] = message.visionImages
        out.content += assets.map { (asset) -> Anthropic.ChatRequestMessage.Content? in
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
                    let content = Anthropic.ChatRequestMessage.Content(
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
