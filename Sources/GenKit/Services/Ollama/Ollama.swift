import Foundation
import OSLog
import Ollama

private let logger = Logger(subsystem: "OllamaService", category: "GenKit")

public actor OllamaService {
    
    private var client: Ollama.Client

    public init(host: URL? = nil) {
        self.client = .init(host: host)
    }
}

// MARK: - Services

extension OllamaService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            tools: encode(request.tools),
            stream: false
        )
        let resp = try await client.chatCompletions(req)
        return decode(resp)
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            tools: encode(request.tools),
            stream: true
        )
        var message = Message(role: .assistant)
        for try await resp in try client.chatCompletionsStream(req) {
            patchMessage(&message, with: resp)
            try await update(message)
            
            // The connection hangs if we don't explicitly return when the stream has stopped.
            if message.finishReason == .stop {
                return
            }
        }
    }
}

extension OllamaService: EmbeddingService {
    
    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = EmbeddingsRequest(model: request.model.id, input: request.input)
        let result = try await client.embeddings(req)
        return result.embedding
    }
}

extension OllamaService: ModelService {
    
    public func models() async throws -> [Model] {
        let resp = try await client.models()
        return resp.models.map { decode($0) }
    }
}

// MARK: - Encoders

extension OllamaService {

    private func encode(messages: [Message]) -> [Ollama.Message] {
        messages.map { message in
            Ollama.Message(
                role: encode(message.role),
                content: encode(message.contents),
                images: encode(message.contents)
            )
        }
    }

    private func encode(_ role: Message.Role) -> Ollama.Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant: .assistant
        case .tool: .tool
        }
    }

    private func encode(_ contents: [Message.Content]?) -> String {
        contents?.compactMap {
            switch $0 {
            case .text(let text): text
            case .json(let json): json.object
            default: ""
            }
        }.joined() ?? ""
    }

    private func encode(_ contents: [Message.Content]?) -> [Data]? {
        let images = contents?.compactMap {
            switch $0 {
            case .image(let image):
                return try? Data(contentsOf: image.url)
            default:
                return nil
            }
        }
        return images?.isEmpty == true ? nil : images
    }

    private func encode(_ tools: [Tool]) -> [Ollama.Tool] {
        tools.map { tool in
            Ollama.Tool(
                type: "function",
                function: .init(
                    name: tool.function.name,
                    description: tool.function.description,
                    parameters: tool.function.parameters
                )
            )
        }
    }
}

// MARK: - Decoders

extension OllamaService {

    private func decode(_ resp: Ollama.ChatResponse) -> Message {
        Message(
            role: decode(resp.message?.role) ?? .assistant,
            content: resp.message?.content,
            toolCalls: resp.message?.tool_calls?.map { decode($0) },
            finishReason: decode(resp.done)
        )
    }

    private func decode(_ role: Ollama.Message.Role?) -> Message.Role? {
        guard let role else { return nil }
        switch role {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        case .tool: return .tool
        }
    }

    private func decode(_ toolCall: Ollama.ToolCall) -> ToolCall {
        ToolCall(
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }

    private func decode(_ done: Bool?) -> Message.FinishReason? {
        guard let done, done else { return nil }
        return .stop
    }

    private func decode(_ model: Ollama.ModelResponse) -> Model {
        Model(
            id: model.model,
            family: model.details?.family,
            name: model.name,
            owner: "ollama",
            contextWindow: nil,
            maxOutput: nil,
            trainingCutoff: nil
        )
    }

    private func patchMessage(_ message: inout Message, with resp: Ollama.ChatResponse) {

        // Patch message content
        if case .text(let text) = message.contents?.last {
            if let patched = GenKit.patch(string: text, with: resp.message?.content) {
                message.contents = [.text(patched)]
            }
        } else if let text = resp.message?.content {
            message.contents = [.text(text)]
        }

        // Patch message tool calls
        if let toolCalls = resp.message?.tool_calls {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            message.toolCalls! += toolCalls.map { decode($0) }
        }

        message.finishReason = decode(resp.done)
        message.modified = .now
    }
}
