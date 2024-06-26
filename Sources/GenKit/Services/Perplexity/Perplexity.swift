import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

public final class PerplexityService {
    
    let client: PerplexityClient
    
    public init(configuration: PerplexityClient.Configuration) {
        self.client = PerplexityClient(configuration: configuration)
        logger.info("Perplexity Service: \(self.client.configuration.host.absoluteString)")
    }
}

extension PerplexityService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages))
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, update: (Message) async -> Void) async throws {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages), stream: true)
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = result.id
            await update(message)
        }
    }
}

extension PerplexityService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0, owner: "perplexity") }
    }
}

extension PerplexityService: ToolService {
    
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let payload = ChatRequest(model: request.model, messages: messages + tools)
        let result = try await client.chat(payload)
        return decode(tool: request.tool, result: result)
    }
    
    public func completionStream(request: ToolServiceRequest, update: (Message) async -> Void) async throws {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let payload = ChatRequest(model: request.model, messages: messages + tools, stream: true)
        for try await result in client.chatStream(payload) {
            var message = decode(tool: request.tool, result: result)
            message.id = result.id
            await update(message)
        }
    }
}
