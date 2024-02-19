import Foundation
import OpenAI

extension OpenAIService {
    
    func encode(messages: [Message]) -> [Chat] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Chat {
        .init(
            role: encode(role: message.role),
            content: message.content,
            name: message.name,
            toolCalls: message.toolCalls?.map { encode(toolCall: $0) },
            toolCallID: message.toolCallID
        )
    }
    
    func encode(role: Message.Role) -> Chat.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(toolCalls: [ToolCall]?) -> [Chat.ToolCall]? {
        toolCalls?.map { encode(toolCall: $0) }
    }
    
    func encode(toolCall: ToolCall) -> Chat.ToolCall {
        .init(
            id: toolCall.id,
            type: toolCall.type,
            function: encode(functionCall: toolCall.function),
            index: toolCall.index
        )
    }
    
    func encode(functionCall: ToolCall.FunctionCall) -> Chat.ToolCall.Function {
        .init(name: functionCall.name, arguments: functionCall.arguments)
    }
    
    func encode(tools: Set<Tool>?) -> [ChatQuery.Tool]? {
        guard let tools, !tools.isEmpty else { return nil }
        return tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> ChatQuery.Tool {
        .init(
            type: tool.type.rawValue,
            function: encode(function: tool.function)
        )
    }

    func encode(function: Tool.Function) -> ChatQuery.Tool.Function {
        .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters
        )
    }
    
    func encode(toolChoice: Tool?) -> ChatQuery.ToolChoice? {
        guard let toolChoice else { return nil }
        return .tool(
            .init(
                type: toolChoice.type.rawValue,
                function: encode(function: toolChoice.function)
            )
        )
    }
    
    func encode(responseFormat: String?) -> AudioTranscriptionQuery.ResponseFormat? {
        guard let responseFormat else { return nil }
        return .init(rawValue: responseFormat)
    }
    
    // Vision
    
    func encode(visionMessages messages: [Message]) -> [ChatVisionMessage] {
        messages.map { encode(visionMessage: $0) }
    }
    
    func encode(visionMessage message: Message) -> ChatVisionMessage {
        if message.attachments.count > 0 {
            return .vision(encode(message: message))
        }
        return .text(encode(message: message))
    }
    
    func encode(message: Message) -> ChatVision {
        // Filter attachments to only images and igonore noops
        let assets: [Asset] = message.attachments
            .map { (attachment) -> Asset? in
                guard case .asset(let asset) = attachment else { return nil }
                return asset
            }
            .filter { $0?.kind == .image }
            .filter { $0?.noop == false }
            .compactMap { $0 }
        
        // Prepare all the image assets attached to the message
        var contents = assets.map { (asset) -> ChatVision.Content? in
            switch asset.location {
            case .url:
                guard let url = asset.url?.absoluteString else { return nil }
                return .init(type: "image_url", imageURL: .init(url: url))
            case .none:
                guard let base64 = asset.data?.base64EncodedString() else { return nil }
                return .init(type: "image_url", imageURL: .init(url: "data:image/png;base64,\(base64)"))
            default:
                return nil
            }
        }.compactMap { $0 }
        
        if let content = message.content {
            contents.append(.init(type: "text", text: content))
        }
        return .init(role: encode(role: message.role), content: contents)
    }
    
    // Speech
    
    func encode(responseFormat: SpeechServiceRequest.ResponseFormat?) throws -> AudioSpeechQuery.ResponseFormat? {
        guard let responseFormat else { return nil }
        switch responseFormat {
        case .mp3:
            return .mp3
        case .opus:
            return .opus
        case .aac:
            return .aac
        case .flac:
            return .flac
        case .custom:
            throw ServiceError.unsupportedResponseFormat
        }
    }
}
