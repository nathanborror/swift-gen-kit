import Foundation
import OSLog
import Ollama

private let logger = Logger(subsystem: "OllamaService", category: "GenKit")

public final class OllamaService {
    
    private var client: OllamaClient
    
    public init(configuration: OllamaClient.Configuration) {
        self.client = OllamaClient(configuration: configuration)
        logger.info("Ollama Service: \(self.client.configuration.host.absoluteString)")
    }
    
    private func prepareToolMessage(_ tool: Tool?) -> Ollama.Message? {
        guard let tool else { return nil }
        guard let paramData = try? JSONEncoder().encode(tool.function.parameters) else { return nil }
        
        let parameters = String(data: paramData, encoding: .utf8) ?? ""
        return Ollama.Message(
            role: .user,
            content: """
                \(tool.function.description)
                Respond using JSON
                
                JSON schema:
                \(parameters)
                """
        )
    }
}

extension OllamaService: ChatService {
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        
        // Prepare messages with tool choice if present
        var messages = encode(messages: request.messages)
        if let toolMessage = prepareToolMessage(request.toolChoice) {
            messages.append(toolMessage)
        }
        
        // Prepare payload
        var payload = ChatRequest(model: request.model, messages: messages)
        
        // Encourage JSON output if tool choice is present
        if request.toolChoice != nil {
            payload.format = "json"
        }
        
        // Result
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages), stream: true)
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = messageID
            await delta(message)
            
            // The connection hangs if we don't explicitly return when the stream has stopped.
            if message.finishReason == .stop {
                return
            }
        }
    }
}

extension OllamaService: EmbeddingService {
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let payload = EmbeddingRequest(model: model, prompt: input, options: [:])
        let result = try await client.embeddings(payload)
        return result.embedding
    }
}

extension OllamaService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map { Model(id: $0.name, owner: "ollama") }
    }
}

extension OllamaService: VisionService {

    public func completion(request: VisionServiceRequest) async throws -> Message {
        let messages = encode(messages: request.messages)
        let payload = ChatRequest(model: request.model, messages: messages)
        let result = try await client.chat(payload)
        return decode(result: result)
    }
    
    public func completionStream(request: VisionServiceRequest, delta: (Message) async -> Void) async throws {
        let payload = ChatRequest(model: request.model, messages: encode(messages: request.messages), stream: true)
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            var message = decode(result: result)
            message.id = messageID
            await delta(message)
            
            // The connection hangs if we don't explicitly return when the stream has stopped.
            if message.finishReason == .stop {
                return
            }
        }
    }
}

extension OllamaService: ToolService {
    
    public func completion(request: ToolServiceRequest) async throws -> Message {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let payload = ChatRequest(model: request.model, messages: messages + tools, format: "json")
        let result = try await client.chat(payload)
        return decode(tool: request.tool, result: result)
    }
    
    public func completionStream(request: ToolServiceRequest, delta: (Message) async -> Void) async throws {
        let messages = encode(messages: request.messages)
        let tools = encode(tools: [request.tool])
        let payload = ChatRequest(model: request.model, messages: messages + tools, stream: true, format: "json")
        let messageID = String.id
        for try await result in client.chatStream(payload) {
            var message = decode(tool: request.tool, result: result)
            message.id = messageID
            await delta(message)
            
            // The connection hangs if we don't explicitly return when the stream has stopped.
            if message.finishReason == .stop {
                return
            }
        }
    }
}
