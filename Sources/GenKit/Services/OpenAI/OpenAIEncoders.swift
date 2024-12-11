import Foundation
import OpenAI

extension OpenAIService {
    
    func encode(messages: [Message]) -> [OpenAI.ChatRequest.Message] {
        messages.map { encode(message: $0) }
    }

    func encode(message: Message) -> OpenAI.ChatRequest.Message {
        .init(
            content: encode(content: message.content),
            role: encode(role: message.role),
            name: message.name,
            tool_calls: message.toolCalls?.map { encode(toolCall: $0) },
            tool_call_id: message.toolCallID
        )
    }

    func encode(content: [Message.Content]?) -> [OpenAI.ChatRequest.Message.Content]? {
        content?.map {
            switch $0 {
            case .text(let text):
                return .init(type: "text", text: text)
            case .image(let data, let format):
                return .init(type: "image_url", image_url: .init(url: "data:\(format.rawValue);base64,\(data.base64EncodedString())"))
            case .audio(let data, let format):
                return .init(type: "input_audio", input_audio: .init(data: data.base64EncodedString(), format: format.rawValue))
            }
        }
    }

    func encode(role: Message.Role) -> OpenAI.ChatRequest.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }
    
    func encode(toolCalls: [ToolCall]?) -> [OpenAI.ChatRequest.Message.ToolCall]? {
        toolCalls?.map { encode(toolCall: $0) }
    }
    
    func encode(toolCall: ToolCall) -> OpenAI.ChatRequest.Message.ToolCall {
        .init(
            id: toolCall.id,
            type: toolCall.type,
            function: encode(functionCall: toolCall.function)
        )
    }
    
    func encode(functionCall: ToolCall.FunctionCall) -> OpenAI.ChatRequest.Message.ToolCall.Function {
        .init(name: functionCall.name, arguments: functionCall.arguments)
    }
    
    func encode(tools: [Tool]?) -> [OpenAI.ChatRequest.Tool]? {
        guard let tools, !tools.isEmpty else { return nil }
        return tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> OpenAI.ChatRequest.Tool {
        .init(
            type: tool.type.rawValue,
            function: encode(function: tool.function)
        )
    }

    func encode(function: Tool.Function) -> OpenAI.ChatRequest.Tool.Function {
        .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters
        )
    }
    
    func encode(toolChoice: Tool?) -> OpenAI.ChatRequest.ToolChoice? {
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
