import Foundation
import OSLog
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

public final class MistralService {
    
    let client: MistralClient
    
    public init(configuration: MistralClient.Configuration) {
        self.client = MistralClient(configuration: configuration)
        logger.info("Mistral Service: \(self.client.configuration.host.absoluteString)")
    }
    
    private func makeRequest(model: String, messages: [Message], tools: Set<Tool> = [], toolChoice: Tool? = nil, stream: Bool = false) -> ChatRequest {
        return .init(
            model: model,
            messages: encode(messages: messages),
            tools: encode(tools: tools),
            toolChoice: encode(toolChoice: toolChoice),
            stream: stream
        )
    }
}

extension MistralService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice)
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, update: (Message) async -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools, toolChoice: request.toolChoice, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatStream(payload) {
            message = decode(result: result, into: message)
            await update(message)
        }
    }
}

extension MistralService: EmbeddingService {
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let payload = EmbeddingRequest(model: model, input: [input])
        let result = try await client.embeddings(payload)
        return result.data.first?.embedding ?? []
    }
}

extension MistralService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { Model(id: $0.id, owner: $0.ownedBy) }
    }
}

extension MistralService: ToolService {
    
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool)
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ToolServiceRequest, update: (Message) async -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatStream(payload) {
            message = decode(result: result, into: message)
            await update(message)
        }
    }
}
