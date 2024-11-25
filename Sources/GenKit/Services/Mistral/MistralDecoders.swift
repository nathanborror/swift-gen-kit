import Foundation
import OSLog
import SharedKit
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

extension MistralService {
    
    func decode(result: ChatResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.message.role),
            content: choice.message.content,
            toolCalls: decode(toolCalls: choice.message.toolCalls),
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
    
    func decode(result: ChatStreamResponse, into message: Message) -> Message {
        var message = message
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        message.content = patch(string: message.content, with: choice.delta.content)
        message.finishReason = decode(finishReason: choice.finishReason)
        message.modified = .now
        message.toolCalls = decode(toolCalls: choice.delta.toolCalls)
        return message
    }
    
    func decode(toolCalls: [Mistral.Message.ToolCall]?) -> [ToolCall]? {
        toolCalls?.map { decode(toolCall: $0) }
    }
    
    func decode(toolCall: Mistral.Message.ToolCall) -> ToolCall {
        .init(
            id: toolCall.id,
            type: "function",
            function: .init(
                name: toolCall.function.name ?? "",
                arguments: toolCall.function.arguments ?? ""
            )
        )
    }

    func decode(role: Mistral.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        case .tool: .tool
        }
    }

    func decode(finishReason: FinishReason?) -> Message.FinishReason? {
        guard let finishReason else { return .none }
        switch finishReason {
        case .stop: 
            return .stop
        case .length, .model_length:
            return .length
        case .tool_calls:
            return .tool_calls
        case .error:
            return .error
        }
    }
    
    func decode(model: Mistral.ModelResponse) -> Model {
        var name = String?.none
        var family = String?.none
        var maxOutput = Int?.none
        var contextWindow = Int?.none
        
        if model.id.hasPrefix("codestral") {
            family = "Codestral"
            switch model.id {
            case "codestral-latest":
                name = "Codestral (latest)"
            case "codestral-2405":
                name = "Codestral (2405)"
            case "codestral-mamba-latest":
                name = "Codestral Mamba (latest)"
            case "codestral-mamba-2407":
                name = "Codestral Mamba (2407)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("mistral-large") {
            family = "Mistral Large"
            switch model.id {
            case "mistral-large-latest":
                name = "Mistral Large (latest)"
            case "mistral-large-2402":
                name = "Mistral Large (2402)"
            case "mistral-large-2407":
                name = "Mistral Large (2407)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("mistral-medium") {
            family = "Mistral Medium"
            switch model.id {
            case "mistral-medium":
                name = "Mistral Medium"
            case "mistral-medium-latest":
                name = "Mistral Medium (latest)"
            case "mistral-medium-2312":
                name = "Mistral Medium (2312)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("mistral-small") {
            family = "Mistral Small"
            switch model.id {
            case "mistral-small":
                name = "Mistral Small"
            case "mistral-small-latest":
                name = "Mistral Small (latest)"
            case "mistral-small-2312":
                name = "Mistral Small (2312)"
            case "mistral-small-2402":
                name = "Mistral Small (2402)"
            case "mistral-small-2409":
                name = "Mistral Small (2409)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("mistral-tiny") {
            family = "Mistral Tiny"
            switch model.id {
            case "mistral-tiny":
                name = "Mistral Tiny"
            case "mistral-tiny-latest":
                name = "Mistral Tiny (latest)"
            case "mistral-tiny-2312":
                name = "Mistral Tiny (2312)"
            case "mistral-tiny-2407":
                name = "Mistral Tiny (2407)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("pixtral") {
            family = "Pixtral"
            switch model.id {
            case "pixtral-12b":
                name = "Pixtral 12b"
            case "pixtral-12b-latest":
                name = "Pixtral 12b (latest)"
            case "pixtral-12b-2409":
                name = "Pixtral 12b (2409)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("open-mistral") {
            family = "Open Mistral"
            switch model.id {
            case "open-mistral-7b":
                name = "Open Mistral 7b"
            case "open-mistral-nemo":
                name = "Open Mistral Nemo"
            case "open-mistral-nemo-2407":
                name = "Open Mistral Nemo (2407)"
            default:
                name = model.id
            }
        }
        
        if model.id.hasPrefix("open-mixtral") {
            family = "Open Mixtral"
            switch model.id {
            case "open-mixtral-8x22b":
                name = "Open Mixtral 8x22b"
            case "open-mixtral-8x22b-2404":
                name = "Open Mixtral 8x22b (2404)"
            case "open-mixtral-8x7b":
                name = "Open Mixtral 8x7b"
            default:
                name = model.id
            }
        }
        
        return Model(
            id: Model.ID(model.id),
            family: family,
            name: name,
            owner: model.ownedBy,
            contextWindow: contextWindow,
            maxOutput: maxOutput,
            trainingCutoff: nil
        )
    }
}
