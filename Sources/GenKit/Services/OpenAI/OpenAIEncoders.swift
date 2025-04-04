import Foundation
import OpenAI

extension OpenAIService {
    
    func encode(messages: [Message]) -> [OpenAI.ChatRequest.Message] {
        messages.map { encode(message: $0) }
    }

    func encode(message: Message) -> OpenAI.ChatRequest.Message {
        .init(
            content: encode(message.contents, role: message.role),
            role: encode(message.role),
            name: message.name,
            tool_calls: message.toolCalls?.map { encode($0) },
            tool_call_id: message.toolCallID
        )
    }

    func encode(_ contents: [Message.Content]?, role: Message.Role) -> [OpenAI.ChatRequest.Message.Content]? {
        contents?.map {
            switch $0 {
            case .text(let text):
                return .init(type: "text", text: text)
            case .image(let url, let format):
                guard role == .user else {
                    return nil
                }
                guard let data = try? Data(contentsOf: url) else {
                    return nil
                }
                return .init(type: "image_url", image_url: .init(url: "data:\(format.rawValue);base64,\(data.base64EncodedString())"))
            case .audio(let url, let format):
                guard role == .user else {
                    return nil
                }
                guard let data = try? Data(contentsOf: url) else {
                    return nil
                }
                return .init(type: "input_audio", input_audio: .init(data: data.base64EncodedString(), format: format.rawValue))
            }
        }.compactMap({$0})
    }

    func encode(_ role: Message.Role) -> OpenAI.ChatRequest.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(_ toolCalls: [ToolCall]?) -> [OpenAI.ChatRequest.Message.ToolCall]? {
        toolCalls?.map { encode($0) }
    }
    
    func encode(_ toolCall: ToolCall) -> OpenAI.ChatRequest.Message.ToolCall {
        .init(
            id: toolCall.id,
            type: toolCall.type,
            function: encode(toolCall.function)
        )
    }
    
    func encode(_ functionCall: ToolCall.FunctionCall) -> OpenAI.ChatRequest.Message.ToolCall.Function {
        .init(name: functionCall.name, arguments: functionCall.arguments)
    }
    
    func encode(_ tools: [Tool]?) -> [OpenAI.ChatRequest.Tool]? {
        guard let tools, !tools.isEmpty else { return nil }
        return tools.map { encode($0) }
    }
    
    func encode(_ tool: Tool) -> OpenAI.ChatRequest.Tool {
        .init(
            type: tool.type.rawValue,
            function: encode(tool.function)
        )
    }

    func encode(_ function: Tool.Function) -> OpenAI.ChatRequest.Tool.Function {
        .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters
        )
    }
    
    func encode(_ toolChoice: Tool?) -> OpenAI.ChatRequest.ToolChoice? {
        guard let toolChoice else { return nil }
        return .tool(
            .init(
                type: toolChoice.type.rawValue,
                function: .init(name: toolChoice.function.name)
            )
        )
    }
    
    func encode(responseFormat: String?) -> OpenAI.TranslationRequest.ResponseFormat? {
        guard let responseFormat else { return nil }
        return .init(rawValue: responseFormat)
    }
    
    // Speech
    
    func encode(responseFormat: String?) throws -> OpenAI.SpeechRequest.ResponseFormat? {
        guard let responseFormat else { return nil }
        switch responseFormat {
        case "mp3":
            return .mp3
        case "opus":
            return .opus
        case "aac":
            return .aac
        case "flac":
            return .flac
        default:
            throw ServiceError.unsupportedResponseFormat
        }
    }
}
