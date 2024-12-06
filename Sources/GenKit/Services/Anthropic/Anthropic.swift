import Foundation
import OSLog
import Anthropic

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

public actor AnthropicService {
    
    let client: Anthropic.Client

    public init(host: URL? = nil, apiKey: String) {
        self.client = .init(host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> ChatRequest {
        let (system, messages) = encode(messages: messages)
        return .init(
            model: model.id.rawValue,
            messages: messages,
            system: system,
            maxTokens: model.maxOutput ?? 8192,
            tools: encode(tools: tools),
            toolChoice: (toolChoice != nil) ? .init(type: .tool, name: toolChoice!.function.name) : nil
        )
    }
}

extension AnthropicService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = (request.temperature != nil) ? Float(request.temperature!) : nil

        let result = try await client.chat(req)
        if let error = result.error { throw error }
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = (request.temperature != nil) ? Float(request.temperature!) : nil
        req.stream = true
        
        var message = Message(role: .assistant)
        for try await result in try client.chatStream(req) {
            if let error = result.error { throw error }
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension AnthropicService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(
                id: Model.ID($0.id),
                name: $0.name,
                owner: $0.owner,
                contextWindow: $0.contextWindow,
                maxOutput: $0.maxOutput
            )
        }
    }
}
