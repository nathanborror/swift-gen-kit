import Foundation
import Llama

public actor LlamaService {

    private let client: Llama.Client

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> Llama.ChatRequest {
        .init(
            model: model.id,
            messages: prepare(messages: messages),
            tools: tools.map { .init($0) },
            tool_choice: (toolChoice != nil) ? .init(toolChoice) : nil
        )
    }

    private func prepare(messages: [Message]) -> [Llama.ChatRequest.Message] {
        return messages
            .map { .init($0) }
    }
}

extension LlamaService: ChatService {

    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        let result = try await client.chatCompletions(req)
        return .init(result)
    }

    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.stream = true

        var message = Message(role: .assistant)
        for try await result in try client.chatCompletionsStream(req) {
            message.patch(with: result)
            try await update(message)
        }
    }
}

extension LlamaService: ModelService {

    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map {
            Model(
                id: $0.id,
                name: $0.id,
                owner: "meta"
            )
        }
    }
}
