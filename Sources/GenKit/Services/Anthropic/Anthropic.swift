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
}

extension AnthropicService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system,
            tools: encode(tools: request.tools)
        )
        let result = try await client.chat(payload)
        if let error = result.error { throw error }
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system,
            tools: encode(tools: request.tools),
            stream: true
        )
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            if let error = result.error { throw error }
            var message = decode(result: result)
            message.id = messageID
            await delta(message)
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
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system
        )
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: VisionServiceRequest, delta: (Message) async -> Void) async throws {
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system,
            stream: true
        )
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = messageID
            await delta(message)
        }
    }
}

extension AnthropicService: ToolService {
    
    /// To encourage explicit tool use add instructions to the user message, like: What's the weather like in London? Use the get_weather tool in your response.
    /// https://docs.anthropic.com/claude/docs/tool-use#forcing-tool-use
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system,
            tools: encode(tools: [request.tool])
        )
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    /// Anthropic doesn't support streaming tool use at this time so we're faking it.
    public func completionStream(request: ToolServiceRequest, delta: (Message) async -> Void) async throws {
        let (system, messages) = encode(messages: request.messages)
        let payload = ChatRequest(
            model: request.model,
            messages: messages,
            system: system,
            tools: encode(tools: [request.tool])
        )
        let result = try await client.chat(payload)
        let message = decode(result: result)
        await delta(message)
    }
}
