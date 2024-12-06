import Foundation
import OpenAI
import SharedKit

extension OpenAIService {
    
    func decode(result: OpenAI.ChatResponse) -> Message {
        let choice = result.choices.first
        var message = Message(
            id: Message.ID(result.id),
            role: decode(role: choice?.message.role ?? "assistant"),
            toolCalls: choice?.message.tool_calls?.map { decode(toolCall: $0) },
            finishReason: decode(finishReason: choice?.finish_reason)
        )
        if let content = choice?.message.content {
            message.content = [.text(content)]
        }
        return message
    }
    
    func decode(result: OpenAI.ChatStreamResponse, into message: Message) -> Message {
        var message = message
        let choice = result.choices.first

        if case .text(let text) = message.content?.last {
            if let patched = patch(string: text, with: choice?.delta.content) {
                message.content = [.text(patched)]
            }
        }
        message.finishReason = decode(finishReason: choice?.finish_reason)
        message.modified = .now
        
        // Convoluted way to add new tool calls and patch the last tool call being streamed in.
        if let toolCalls = choice?.delta.tool_calls {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            for toolCall in toolCalls {
                // TODO: FIX THIS
                if toolCall.id == nil {
                    if var existing = message.toolCalls?.last {
                        existing.function.arguments = patch(string: existing.function.arguments, with: toolCall.function.arguments) ?? ""
                        message.toolCalls![message.toolCalls!.count-1] = existing
                    }
                } else {
                    let newToolCall = decode(toolCall: toolCall)
                    message.toolCalls?.append(newToolCall)
                }
            }
        }
        return message
    }

    func decode(role: String) -> Message.Role {
        switch role {
        case "system": .system
        case "user": .user
        case "assistant": .assistant
        case "tool": .tool
        default: .assistant
        }
    }

    func decode(finishReason: String?) -> Message.FinishReason? {
        switch finishReason {
        case "stop": .stop
        case "length": .length
        case "tool_calls": .tool_calls
        case "content_filter": .content_filter
        default: nil
        }
    }

    func decode(toolCall: OpenAI.ChatResponse.Choice.Message.ToolCall) -> ToolCall {
        .init(
            id: toolCall.id,
            type: toolCall.type,
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    func decode(model: OpenAI.Model) -> Model {
        var name = String?.none
        var family = String?.none
        var maxOutput = Int?.none
        var contextWindow = Int?.none
        
        if model.id.hasPrefix("gpt-3.5") {
            family = "GPT 3.5"
            
            switch model.id {
            case "gpt-3.5-turbo":
                name = "GPT 3.5 Turbo"
                contextWindow = 16_385
                maxOutput = 4096
            case "gpt-3.5-turbo-0125":
                name = "GPT 3.5 Turbo (2024-01-25)"
                contextWindow = 16_385
                maxOutput = 4096
            case "gpt-3.5-turbo-11-06":
                name = "GPT 3.5 Turbo (2023-11-06)"
                contextWindow = 16_385
                maxOutput = 4096
            case "gpt-3.5-turbo-instruct":
                name = "GPT 3.5 Turbo (instruct)"
                contextWindow = 4096
                maxOutput = 4096
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("gpt-4o") || model.id.hasPrefix("chatgpt-4o") {
            family = "GPT 4o"
            
            switch model.id {
            case "gpt-4o":
                name = "GPT 4o"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4o-2024-05-13":
                name = "GPT 4o (2024-05-13)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4o-2024-08-06":
                name = "GPT 4o (2024-08-06)"
                contextWindow = 128_000
                maxOutput = 4096
            case "chatgpt-4o-latest":
                name = "GPT 4o (chatgpt latest)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4o-mini":
                name = "GPT 4o Mini"
                contextWindow = 128_000
                maxOutput = 16_384
            case "gpt-4o-mini-2024-07-18":
                name = "GPT 4o Mini (2024-07-18)"
                contextWindow = 128_000
                maxOutput = 16_384
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("gpt-4-") || model.id == "gpt-4" {
            family = "GPT 4"
            
            switch model.id {
            case "gpt-4-turbo":
                name = "GPT 4 Turbo"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4-turbo-2024-04-09":
                name = "GPT 4 Turbo (2024-04-09)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4-turbo-preview":
                name = "GPT 4 Turbo (preview)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4-0125-preview":
                name = "GPT 4 Turbo (2024-01-25)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4-1106-preview":
                name = "GPT 4 Turbo (2023-11-06)"
                contextWindow = 128_000
                maxOutput = 4096
            case "gpt-4":
                name = "GPT 4"
                contextWindow = 8192
                maxOutput = 8192
            case "gpt-4-0613":
                name = "GPT 4 (2023-06-13)"
                contextWindow = 8192
                maxOutput = 8192
            case "gpt-4-0314":
                name = "GPT 4 (2023-03-14)"
                contextWindow = 8192
                maxOutput = 8192
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("o1") {
            family = "o1"
            
            switch model.id {
            case "o1-preview":
                name = "o1 Preview"
                contextWindow = 128_000
                maxOutput = 32_768
            case "o1-preview-2024-09-12":
                name = "o1 Preview (2024-09-12)"
                contextWindow = 128_000
                maxOutput = 32_768
            case "o1-mini":
                name = "o1 Mini"
                contextWindow = 128_000
                maxOutput = 65_536
            case "o1-mini-2024-09-12":
                name = "o1 Mini (2024-09-12)"
                contextWindow = 128_000
                maxOutput = 65_536
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("dall-e") {
            family = "DALL·E"
            
            switch model.id {
            case "dall-e-3":
                name = "DALL·E 3"
            case "dall-e-2":
                name = "DALL·E 2"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("tts-") {
            family = "TTS"
            
            switch model.id {
            case "tts-1":
                name = "TTS 1"
            case "tts-1-hd":
                name = "TTS 1 HD"
            case "tts-1-1106":
                name = "TTS 1 (2023-11-06)"
            case "tts-1-hd-1106":
                name = "TTS 1 HD (2023-11-06)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("text-embedding") {
            family = "Text Embedding"
            
            switch model.id {
            case "text-embedding-3-large":
                name = "Text Embedding 3 (large)"
            case "text-embedding-3-small":
                name = "Text Embedding 3 (small)"
            case "text-embedding-ada-002":
                name = "Text Embedding 2 (ada)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("babbage") || model.id.hasPrefix("davinci") {
            family = "GPT Base"
            
            switch model.id {
            case "babbage-002":
                name = "GPT Base (babbage)"
                maxOutput = 16_384
            case "davinci-002":
                name = "GPT Base (davinci)"
                maxOutput = 16_384
            default:
                name = model.id
            }
        }
        
        if model.id == "whisper-1" {
            name = "Whisper"
        }
        
        return Model(
            id: Model.ID(model.id),
            family: family,
            name: name,
            owner: model.owned_by,
            contextWindow: contextWindow,
            maxOutput: maxOutput,
            trainingCutoff: nil
        )
    }
}
