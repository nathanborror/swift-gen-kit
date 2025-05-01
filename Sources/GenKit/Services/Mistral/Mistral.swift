import Foundation
import OSLog
import Mistral

private let logger = Logger(subsystem: "MistralService", category: "GenKit")

public actor MistralService {
    
    private let client: Mistral.Client

    public init(host: URL? = nil, apiKey: String) {
        self.client = .init(host: host, apiKey: apiKey)
    }
}

// MARK: - Services

extension MistralService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        var req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            tools: encode(request.tools),
            tool_choice: encode(request.toolChoice)
        )
        req.temperature = request.temperature
        
        let resp = try await client.chatCompletions(req)
        guard let message = decode(resp) else {
            throw ChatServiceError.responseError("Missing response choice")
        }
        return message
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = ChatRequest(
            model: request.model.id,
            messages: encode(messages: request.messages),
            tools: encode(request.tools),
            tool_choice: encode(request.toolChoice)
        )
        req.temperature = request.temperature
        req.stream = true
        
        var message = Message(role: .assistant)
        for try await resp in try client.chatCompletionsStream(req) {
            patchMessage(&message, with: resp)
            try await update(message)
        }
    }
}

extension MistralService: EmbeddingService {
    
    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = EmbeddingsRequest(model: request.model.id, input: [request.input])
        let result = try await client.embeddings(req)
        return result.data.first?.embedding ?? []
    }
}

extension MistralService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode($0) }
    }
}

// MARK: - Encoders

extension MistralService {
    
    private func encode(messages: [Message]) -> [Mistral.ChatRequest.Message] {
        messages.map { message in
            Mistral.ChatRequest.Message(
                content: encode(message.contents),
                tool_calls: encode(message.toolCalls),
                prefix: nil,
                role: encode(message.role)
            )
        }
    }
    
    private func encode(_ role: Message.Role) -> Mistral.ChatRequest.Message.Role {
        switch role {
        case .system: .system
        case .user: .user
        case .assistant: .assistant
        case .tool: .tool
        }
    }
    
    private func encode(_ contents: [Message.Content]?) -> [Mistral.ChatRequest.Message.Content]? {
        contents?.compactMap { content in
            switch content {
            case .text(let text):
                return .init(type: .text, text: text)
            case .image(let image):
                guard let data = try? Data(contentsOf: image.url) else { return nil }
                return .init(type: .image_url, image_url: .init(url: "data:image/\(image.format);base64,\(data.base64EncodedString())"))
            case .json(let json):
                return .init(type: .text, text: json.object)
            default:
                return nil
            }
        }
    }
    
    private func encode(_ toolCalls: [ToolCall]?) -> [Mistral.ChatRequest.Message.ToolCall]? {
        toolCalls?.map { toolCall in
            Mistral.ChatRequest.Message.ToolCall(
                id: toolCall.id,
                function: .init(
                    name: toolCall.function.name,
                    arguments: toolCall.function.arguments
                )
            )
        }
    }
    
    private func encode(_ tools: [Tool]) -> [Mistral.ChatRequest.Tool] {
        tools.map { tool in
            Mistral.ChatRequest.Tool(
                function: .init(
                    name: tool.function.name,
                    description: tool.function.description,
                    parameters: tool.function.parameters
                )
            )
        }
    }
    
    private func encode(_ toolChoice: Tool?) -> Mistral.ChatRequest.ToolChoice? {
        guard let toolChoice else { return nil }
        return .tool(.init(function: .init(name: toolChoice.function.name)))
    }
}

// MARK: - Decoders

extension MistralService {

    private func decode(_ resp: Mistral.ChatResponse) -> Message? {
        guard let choice = resp.choices.first else { return nil }
        return Message(
            role: .assistant,
            content: choice.message.content,
            toolCalls: choice.message.tool_calls?.map { decode($0) },
            finishReason: decode(choice.finish_reason)
        )
    }
    
    private func decode(_ toolCall: Mistral.ChatResponse.Choice.Message.ToolCall) -> ToolCall {
        ToolCall(
            id: toolCall.id ?? "",
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    private func decode(_ reason: Mistral.ChatResponse.Choice.FinishReason?) -> Message.FinishReason? {
        guard let reason else { return nil }
        switch reason {
        case .stop:
            return .stop
        case .length, .model_length:
            return .length
        case .error:
            return .error
        case .tool_calls:
            return .toolCalls
        }
    }
    
    private func decode(_ model: Mistral.ModelsResponse.Model) -> Model {
        Model(
            id: model.id,
            name: model.name,
            owner: model.owned_by ?? "mistral",
            contextWindow: model.max_context_length,
            maxOutput: model.max_context_length,
            trainingCutoff: nil
        )
    }
    
    private func decode(_ reason: Mistral.ChatStreamResponse.Choice.FinishReason?) -> Message.FinishReason? {
        guard let reason else { return nil }
        switch reason {
        case .stop:
            return .stop
        case .length, .model_length:
            return .length
        case .error:
            return .error
        case .tool_calls:
            return .toolCalls
        }
    }
    
    private func decode(_ toolCall: Mistral.ChatStreamResponse.Choice.Message.ToolCall) -> ToolCall {
        ToolCall(
            id: toolCall.id ?? "",
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    private func patchMessage(_ message: inout Message, with resp: Mistral.ChatStreamResponse) {
        // If there is no choice, return existing message
        guard let choice = resp.choices.first else {
            return
        }

        // Patch message content
        if case .text(let text) = message.contents?.last, let delta = choice.delta.content {
            if let patched = GenKit.patch(string: text, with: delta) {
                message.contents = [.text(patched)]
            }
        } else if let delta = choice.delta.content {
            message.contents = [.text(delta)]
        }

        // Patch message tool calls
        if let toolCalls = choice.delta.tool_calls {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            message.toolCalls! += toolCalls.map { decode($0) }
        }

        message.finishReason = decode(choice.finish_reason)
        message.modified = .now
    }
}
