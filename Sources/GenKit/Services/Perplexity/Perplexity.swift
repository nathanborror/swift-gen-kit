import Foundation
import OSLog
import Perplexity

private let logger = Logger(subsystem: "PerplexityService", category: "GenKit")

public actor PerplexityService {
    
    let client: PerplexityClient
    
    public init(configuration: PerplexityClient.Configuration) {
        self.client = PerplexityClient(configuration: configuration)
    }
}

extension PerplexityService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: request.temperature
        )
        let result = try await client.chat(req)
        return decode(result: result)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            temperature: request.temperature,
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

extension PerplexityService: ToolService {
    
    public func completion(_ request: ToolServiceRequest) async throws -> Message {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let req = ChatRequest(
            model: request.model.id,
            messages: messages + tools,
            temperature: request.temperature
        )
        let result = try await client.chat(req)
        return decode(tool: request.tool, result: result)
    }
    
    public func completionStream(_ request: ToolServiceRequest, update: (Message) async throws -> Void) async throws {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let req = ChatRequest(
            model: request.model.id,
            messages: messages + tools,
            temperature: request.temperature,
            stream: true
        )
        var message = Message(role: .assistant)
        for try await result in try client.chatStream(req) {
            message = decode(result: result, into: message)
            try await update(message)
        }
    }
}
