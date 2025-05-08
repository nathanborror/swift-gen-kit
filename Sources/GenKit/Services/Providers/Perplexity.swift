import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

public actor PerplexityService {
    
    private let client: Perplexity.Client

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
    }
}

// MARK: - Services

extension PerplexityService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: (request.temperature != nil) ? Float(request.temperature!) : nil
        )
        let result = try await client.chat(req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: (request.temperature != nil) ? Float(request.temperature!) : nil,
            stream: true
        )
        var message = Message(role: .assistant)
        for try await result in try client.chatStream(req) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension PerplexityService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(id: $0.id, name: $0.name, owner: $0.owner, contextWindow: $0.contextWindow)
        }
    }
}

// MARK: - Encoders

extension PerplexityService {
    
    func encode(messages: [Message]) -> [Perplexity.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Perplexity.Message {
        .init(
            role: encode(role: message.role),
            content: encode(contents: message.contents) ?? ""
        )
    }

    func encode(contents: [Message.Content]?) -> String? {
        contents?.compactMap {
            switch $0 {
            case .text(let text):
                return text
            case .json(let json):
                return json.object
            default:
                return nil
            }
        }.joined()
    }

    func encode(tools: [Tool]) -> [Perplexity.Message] {
        tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Perplexity.Message {
        let jsonData = try? JSONEncoder().encode(tool.function.parameters)
        let json = String(data: jsonData!, encoding: .utf8)!
        
        return .init(
            role: .user,
            content: """
                Consider the following JSON Schema based on the 2020-12 specification:
                
                ```json
                \(json)
                ```
                
                This JSON Schema represents the format I want you to follow to generate your answer. You will only \
                respond with a JSON object. Do not provide explanations. Generate a JSON object that will contain \
                the following information:
                
                \(tool.function.description)
                """
        )
    }
    
    func encode(role: Message.Role) -> Perplexity.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}

// MARK: - Decoders

extension PerplexityService {
    
    func decode(result: ChatResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        var message = Message(
            role: decode(role: choice.message.role),
            finishReason: decode(finishReason: choice.finishReason)
        )
        if case .text(let text) = message.contents?.last {
            if let patched = patch(string: text, with: choice.message.content) {
                message.contents = [.text(patched)]
            }
        }
        return message
    }
    
    func decode(result: ChatStreamResponse, into message: Message) -> Message {
        var message = message
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        if case .text(let text) = message.contents?.last {
            if let patched = patch(string: text, with: choice.delta.content) {
                message.contents = [.text(patched)]
            }
        }
        message.finishReason = decode(finishReason: choice.finishReason)
        message.modified = .now
        return message
    }

    func decode(role: Perplexity.Message.Role?) -> Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant, .none: .assistant
        }
    }

    func decode(content: String, into message: Message) -> [Message.Content] {
        guard message.role == .assistant else { return [] }
        guard
            let existing = message.contents, content.count > 0,
            case .text(let existingText) = existing.last,
            let patched = patch(string: existingText, with: content)
        else {
            return [.text(content)]
        }
        return [.text(patched)]
    }

    func decode(finishReason: FinishReason?) -> Message.FinishReason? {
        guard let finishReason else { return .none }
        switch finishReason {
        case .stop:
            return .stop
        case .length, .model_length:
            return .length
        }
    }

    // Tools

    func decode(tool: Tool, result: ChatResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.message.role),
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.message.content))
            ],
            finishReason: decode(finishReason: choice.finishReason)
        )
    }

    func decode(tool: Tool, result: ChatStreamResponse) -> Message {
        guard let choice = result.choices.first else {
            logger.warning("failed to decode choice")
            return .init(role: .assistant)
        }
        return .init(
            role: decode(role: choice.delta.role),
            toolCalls: [
                .init(id: .id, type: "function", function: .init(name: tool.function.name, arguments: choice.message.content))
            ],
            finishReason: decode(finishReason: choice.finishReason)
        )
    }
}