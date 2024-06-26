import Foundation
import OSLog
import Anthropic

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

public final class AnthropicService {
    
    let client: AnthropicClient
    
    public init(configuration: AnthropicClient.Configuration) {
        self.client = AnthropicClient(configuration: configuration)
        logger.info("Anthropic Service: \(self.client.configuration.host.absoluteString)")
    }
    
    private func makeRequest(model: String, messages: [Message], tools: Set<Tool> = [], toolChoice: Tool? = nil, stream: Bool = false) -> ChatRequest {
        let (system, messages) = encode(messages: messages)
        return .init(
            model: model,
            messages: messages,
            system: system,
            tools: encode(tools: tools),
            toolChoice: (toolChoice != nil) ? .init(type: .tool, name: toolChoice!.function.name) : nil,
            stream: stream
        )
    }
}

extension AnthropicService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        let result = try await client.chat(payload)
        if let error = result.error { throw error }
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, update: (Message) async -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: request.tools, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatStream(payload) {
            if let error = result.error { throw error }
            message = decode(result: result, into: message)
            await update(message)
        }
    }
}

extension AnthropicService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0, owner: "anthropic") }
    }
}

extension AnthropicService: VisionService {
    
    public func completion(request: VisionServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages)
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: VisionServiceRequest, update: (Message) async -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatStream(payload) {
            if let error = result.error { throw error }
            message = decode(result: result, into: message)
            await update(message)
        }
    }
}

extension AnthropicService: ToolService {
    
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool)
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ToolServiceRequest, update: (Message) async -> Void) async throws {
        let payload = makeRequest(model: request.model, messages: request.messages, tools: [request.tool], toolChoice: request.tool, stream: true)
        var message = Message(role: .assistant)
        for try await result in client.chatStream(payload) {
            if let error = result.error { throw error }
            message = decode(result: result, into: message)
            await update(message)
        }
    }
}
