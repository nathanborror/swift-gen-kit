import Foundation
import OSLog
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

public actor MistralService {
    
    let client: Mistral.Client

    public init(host: URL? = nil, apiKey: String) {
        self.client = .init(host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model.ID, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> ChatRequest {
        return .init(
            model: model.rawValue,
            messages: messages.map { .init($0) },
            tools: encode(tools: tools),
            tool_choice: encode(toolChoice: toolChoice)
        )
    }
}

extension MistralService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        var req = makeRequest(model: request.model.id, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice)
        req.temperature = request.temperature

        let result = try await client.chatCompletions(req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model.id, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice)
        req.temperature = request.temperature
        req.stream = true
        
        var message = Message(role: .assistant)
        for try await result in try client.chatCompletionsStream(req) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}

extension MistralService: EmbeddingService {
    
    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = EmbeddingsRequest(model: request.model.id.rawValue, input: [request.input])
        let result = try await client.embeddings(req)
        return result.data.first?.embedding ?? []
    }
}

extension MistralService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode(model: $0) }
    }
}
