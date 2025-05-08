import Foundation
import Llama
import OSLog

private let logger = Logger(subsystem: "LlamaService", category: "GenKit")

public actor LlamaService {

    private let client: Llama.Client

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> Llama.ChatRequest {
        .init(
            model: model.id,
            messages: encode(messages: messages),
            tools: encode(tools),
            tool_choice: encode(toolChoice)
        )
    }
}

// MARK: - Services

extension LlamaService: ChatService {

    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        let result = try await client.chatCompletions(req)
        return decode(result)
    }

    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.stream = true

        var message = Message(role: .assistant)
        for try await result in try client.chatCompletionsStream(req) {
            patchMessage(&message, with: result)
            try await update(message)
        }
    }
}

extension LlamaService: ModelService {

    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode($0) }
    }
}

// MARK: - Encoders

extension LlamaService {
    
    private func encode(messages: [Message]) -> [Llama.ChatRequest.Message] {
        return messages.map { encode($0) }
    }
    
    private func encode(_ message: Message) -> Llama.ChatRequest.Message {
        let content = message.contents?.compactMap { encode($0) } ?? []
        return .init(
            role: encode(message.role),
            content: content,
            tool_call_id: message.toolCallID,
            tool_calls: message.toolCalls?.map { encode($0) },
            stop_reason: encode(message.finishReason)
        )
    }
    
    private func encode(_ content: Message.Content) -> Llama.ChatRequest.Message.Content? {
        switch content {
        case .text(let text):
            return .init(text: text)
        case .image(let image):
            if let data = try? Data(contentsOf: image.url) {
                return .init(image: "data:image/\(image.format);base64,\(data.base64EncodedString())")
            }
            return nil
        case .json(let json):
            return .init(text: """
                ```json \(json.kind)
                \(json.object)
                ```
                """)
        case .file(let file):
            guard
                let data = try? Data(contentsOf: file.url),
                let content = String(data: data, encoding: .utf8) else { return nil }
            return .init(text: """
                ```\(file.mimetype.preferredFilenameExtension ?? "txt") \(file.url.lastPathComponent)
                \(content)
                ```
                """)
        case .audio:
            return nil
        }
    }
    
    private func encode(_ role: Message.Role) -> Llama.ChatRequest.Message.Role {
        switch role {
        case .system: return .system
        case .assistant: return .assistant
        case .user: return .user
        case .tool: return .tool
        }
    }
    
    private func encode(_ tools: [Tool]) -> [Llama.Tool] {
        tools.map { encode($0) }
    }
    
    private func encode(_ tool: Tool) -> Llama.Tool {
        .init(
            type: "function",
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
    
    private func encode(_ toolChoice: Tool?) -> Llama.ToolChoice? {
        guard let toolChoice else { return nil }
        return .init(
            type: "function",
            function: .init(name: toolChoice.function.name)
        )
    }
    
    private func encode(_ toolCall: ToolCall) -> Llama.ToolCall {
        .init(
            id: toolCall.id,
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    private func encode(_ finishReason: Message.FinishReason?) -> Llama.StopReason? {
        guard let finishReason else { return nil }
        switch finishReason {
        case .stop: return .stop
        case .length: return .length
        case .toolCalls: return .tool_calls
        default: return nil
        }
    }
}

// MARK: - Decoders

extension LlamaService {
    
    private func decode(_ resp: Llama.ChatResponse) -> Message {
        Message(
            role: .assistant,
            contents: [decode(resp.completion_message.content)].compactMap { $0 },
            toolCalls: resp.completion_message.tool_calls?.map { decode($0) },
            finishReason: decode(resp.completion_message.stop_reason)
        )
    }
    
    private func decode(_ content: Llama.ChatResponse.CompletionMessage.Content) -> Message.Content? {
        if let text = content.text {
            return .text(text)
        } else if let reasoning = content.reasoning {
            return .text(reasoning)
        } else if let answer = content.answer {
            return .text(answer)
        }
        return nil
    }
    
    private func decode(_ toolCall: Llama.ToolCall) -> ToolCall {
        ToolCall(
            id: toolCall.id,
            type: "function",
            function: .init(
                name: toolCall.function.name,
                arguments: toolCall.function.arguments
            )
        )
    }
    
    private func decode(_ stopReason: Llama.StopReason?) -> Message.FinishReason? {
        guard let stopReason else { return nil }
        switch stopReason {
        case .stop: return .stop
        case .length: return .length
        case .tool_calls: return .toolCalls
        }
    }
    
    private func decode(_ model: Llama.Model) -> Model {
        Model(
            id: model.id,
            name: model.id,
            owner: "meta"
        )
    }
    
    private func patchMessage(_ message: inout Message, with resp: Llama.ChatStreamResponse) {
        var contents = message.contents ?? []

        if ["start", "progress", "complete"].contains(resp.event.event_type) {
            if case .text(let text) = contents.last, let delta = resp.event.delta.text {
                if let patched = GenKit.patch(string: text, with: delta) {
                    contents[contents.count-1] = .text(patched)
                }
            } else if let delta = resp.event.delta.text {
                contents.append(.text(delta))
            }
        }

        message.contents = (contents.isEmpty) ? nil : contents
        message.toolCalls = []
        message.finishReason = decode(resp.event.stop_reason)
        message.modified = .now
    }
}
