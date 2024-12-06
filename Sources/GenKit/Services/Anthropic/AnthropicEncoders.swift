import Foundation
import Anthropic
import SharedKit

extension AnthropicService {
    
    // Extract all system messages and combine into one because Anthropic accepts a single system prompt as part of the
    // chat request instead of system messages. Combine multiple user messages so we always have alternating user and
    // assistant messages.
    func encode(messages: [Message]) -> (String?, [Anthropic.ChatRequest.Message]) {
        
        // When there's just one message it has to be from the user.
        if messages.count == 1 {
            var message = messages[0]
            message.role = .user // force this to be a user message
            return (nil, [encode(message: message)])
        }
        
        // Proceed as normal
//        let system = messages
//            .filter { $0.role == .system }
//            .map { $0.content }
//            .compactMap { $0 }
//            .joined(separator: "\n\n")
        
//        let messagesFiltered = messages
//            .filter { $0.role != .system }
//            .map { encode(message: $0) }
        
        let messagesCleaned = messagesFiltered.reduce(into: [Anthropic.ChatRequest.Message]()) { result, message in
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
    
    func encode(message: Message) -> Anthropic.ChatRequest.Message {
        var out = Anthropic.ChatRequest.Message(
            role: encode(role: message.role),
            content: encode(content: message.content)
        )
        
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
        
        // Append attachments
        let fileContents = message.attachments.filter {
            if case .file = $0 {
                return true
            }
            return false
        }.compactMap {
            if case let .file(_, content) = $0 {
                return content
            }
            return nil
        }
        
        if !fileContents.isEmpty {
            out.content.append(
                .init(
                    type: .text,
                    text: """
                    <file_attachment_content>
                        \(fileContents.joined(separator: "\n\n --- \n\n"))
                    </file_attachment_content>
                    """
                )
            )
        }
        
        // Handle tool responses or append message content
        if message.role == .tool {
            out.content.append(
                .init(
                    type: .tool_result,
                    content: [
                        .init(
                            type: .text,
                            text: message.content
                        )
                    ],
                    toolUseID: message.toolCallID
                )
            )
        } else {
            if let text = message.content {
                out.content.append(.init(type: .text, text: text))
            }
        }
        return out
    }

    func encode(content: [Message.Content]?) -> [Anthropic.ChatRequest.Message.Content] {
        content?.compactMap {
            switch $0 {
            case .text(let text):
                return .init(type: .text, text: text)
            case .image(data: let data):
                return .init(type: .image, source: .init(type: .base64, mediaType: .png, data: data))
            default:
                return nil
            }
        } ?? []
    }

    func encode(role: Message.Role) -> Anthropic.Role {
        switch role {
        case .system, .user, .tool: .user
        case .assistant: .assistant
        }
    }
    
    func encode(tools: [Tool]) -> [Anthropic.ChatRequest.Tool]? {
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
