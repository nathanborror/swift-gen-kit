import Foundation
import OSLog
import Anthropic

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

public actor AnthropicService {

    let client: Anthropic.Client

    public init(host: URL? = nil, apiKey: String) {
        self.client = .init(host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> Anthropic.ChatRequest {
        .init(
            model: model.id,
            messages: prepare(messages: messages),
            max_tokens: model.maxOutput ?? 8192,
            system: prepareSystemPrompt(from: messages),
            tool_choice: (toolChoice != nil) ? .init(type: .tool, name: toolChoice!.function.name) : nil,
            tools: tools.map { .init($0) }
        )
    }

    private func prepare(messages: [Message]) -> [Anthropic.ChatRequest.Message] {
        return messages
            .filter { $0.role != .system }
            .map { .init($0) }
    }

    private func prepareSystemPrompt(from messages: [Message]) -> [Anthropic.ChatRequest.Message.Content]? {
        guard let message = messages.first, message.role == .system else { return nil }
        guard case .text(let text) = message.contents?.first else { return nil }
        return [.init(type: .text, text: text)]
    }
}

extension AnthropicService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = request.temperature
        let result = try await client.chatCompletions(req)
        return .init(result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = request.temperature
        req.stream = true
        
        var message = Message(role: .assistant)
        for try await result in try client.chatCompletionsStream(req) {
            message.patch(with: result)
            try await update(message)
        }
    }
}

extension AnthropicService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map {
            Model(
                id: $0.id,
                name: $0.display_name,
                owner: "anthropic"
            )
        }
    }
}
