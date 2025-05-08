import Foundation
import OSLog
import Anthropic
import JSONSchema
import SharedKit

private let logger = Logger(subsystem: "AnthropicService", category: "GenKit")

public actor AnthropicService {

    private let client: Anthropic.Client

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
    }

    private func makeRequest(model: Model, messages: [Message], tools: [Tool] = [], toolChoice: Tool? = nil) -> Anthropic.ChatRequest {
        .init(
            model: model.id,
            messages: encode(messages: messages),
            max_tokens: model.maxOutput ?? 8192,
            system: encodeSystemPrompt(from: messages),
            tool_choice: encode(toolChoice),
            tools: encode(tools)
        )
    }
}

// MARK: - Services

extension AnthropicService: ChatService {

    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = request.temperature
        let result = try await client.chatCompletions(req)
        return decode(result)
    }

    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        var req = makeRequest(model: request.model, messages: request.messages, tools: request.tools)
        req.temperature = request.temperature
        req.stream = true

        var message = Message(role: .assistant)
        for try await result in try client.chatCompletionsStream(req) {
            patchMessage(&message, with: result)
            try await update(message)
        }
    }
}

extension AnthropicService: ModelService {

    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode($0) }
    }
}

// MARK: - Encoders

extension AnthropicService {

    private func encode(messages: [Message]) -> [Anthropic.ChatRequest.Message] {
        return messages
            .filter { $0.role != .system }
            .map { message in
                Anthropic.ChatRequest.Message(
                    role: encode(message.role),
                    content: message.contents?.compactMap { encode($0) } ??
                            message.toolCalls?.compactMap { encode($0) } ??
                            [encode(message)].compactMap { $0 }
                )
            }
    }

    private func encodeSystemPrompt(from messages: [Message]) -> [Anthropic.ChatRequest.Message.Content]? {
        guard let message = messages.first, message.role == .system else { return nil }
        guard case .text(let text) = message.contents?.first else { return nil }
        return [.init(type: .text, text: text)]
    }

    private func encode(_ role: Message.Role) -> Anthropic.ChatRequest.Message.Role {
        switch role {
        case .system, .user, .tool:
            return .user
        case .assistant:
            return .assistant
        }
    }

    private func encode(_ content: Message.Content) -> Anthropic.ChatRequest.Message.Content? {
        switch content {
        case .text(let text):
            return .init(type: .text, text: text)
        case .image(let image):
            if let data = try? Data(contentsOf: image.url) {
                return .init(
                    type: .image,
                    source: .init(
                        type: .base64,
                        media_type: .init(rawValue: image.format.rawValue) ?? .png,
                        data: data
                    )
                )
            } else {
                return nil
            }
        case .audio:
            return nil
        case .json(let json):
            return .init(type: .text, text: json.object)
        case .file(let file):
            guard
                let data = try? Data(contentsOf: file.url),
                let content = String(data: data, encoding: .utf8) else { return nil }
            return .init(type: .text, text: """
                ```\(file.mimetype.preferredFilenameExtension ?? "txt") \(file.url.lastPathComponent)
                \(content)
                ```
                """)
        }
    }

    private func encode(_ toolCall: ToolCall) -> Anthropic.ChatRequest.Message.Content? {
        guard let data = toolCall.function.arguments.data(using: .utf8) else { return nil }
        guard let input = try? JSONDecoder().decode([String: JSONValue].self, from: data) else { return nil }
        return .init(
            type: .tool_use,
            id: toolCall.id,
            name: toolCall.function.name,
            input: input
        )
    }

    private func encode(_ message: Message) -> Anthropic.ChatRequest.Message.Content? {
        guard message.role == .tool else { return nil }
        return .init(
            type: .tool_result,
            tool_use_id: message.toolCallID,
            content: message.contents?.compactMap { encode($0) }
        )
    }

    private func encode(_ tools: [Tool]) -> [Anthropic.ChatRequest.Tool] {
        tools.map { tool in
            Anthropic.ChatRequest.Tool(
                name: tool.function.name,
                description: tool.function.description,
                input_schema: tool.function.parameters
            )
        }
    }

    private func encode(_ toolChoice: Tool?) -> Anthropic.ChatRequest.ToolChoice? {
        guard let toolChoice else {
            return .init(type: .auto)
        }
        return .init(
            type: .tool,
            name: toolChoice.function.name
        )
    }
}

// MARK: - Decoders

extension AnthropicService {

    private func decode(_ resp: Anthropic.ChatResponse) -> Message {
        Message(
            role: decode(resp.role) ?? .assistant,
            contents: resp.content?.compactMap { decode($0) } ?? [],
            toolCalls: resp.content?.compactMap { decodeToolCall($0) },
            finishReason: decode(resp.stop_reason)
        )
    }

    private func decode(_ role: Anthropic.ChatResponse.Role?) -> Message.Role? {
        guard let role else { return nil }
        switch role {
        case .assistant:
            return .assistant
        case .user:
            return .user
        }
    }

    private func decode(_ content: Anthropic.ChatResponse.Content) -> Message.Content? {
        switch content.type {
        case .text, .text_delta:
            if let text = content.text {
                return .text(text)
            } else {
                return nil
            }
        case .tool_use, .input_json_delta, .none, .thinking_delta, .redacted_thinking, .signature_delta:
            return nil
        }
    }

    private func decode(_ reason: Anthropic.ChatResponse.StopReason?) -> Message.FinishReason? {
        guard let reason else { return nil }
        switch reason {
        case .end_turn:
            return .stop
        case .max_tokens:
            return .length
        case .stop_sequence:
            return .stop
        case .tool_use:
            return .toolCalls
        }
    }

    private func decodeToolCall(_ content: Anthropic.ChatResponse.Content) -> ToolCall? {
        switch content.type {
        case .tool_use:
            let data = try? JSONEncoder().encode(content.input)
            let arguments = (data != nil) ? String(data: data!, encoding: .utf8)! : ""
            return ToolCall(
                id: content.id ?? .id,
                function: .init(
                    name: content.name ?? "",
                    arguments: arguments
                )
            )
        case .text, .text_delta, .input_json_delta, .none, .thinking_delta, .redacted_thinking, .signature_delta:
            return nil
        }
    }

    private func decode(_ model: Anthropic.Model) -> Model {
        Model(
            id: model.id,
            name: model.display_name,
            owner: "anthropic"
        )
    }

    private func patchMessage(_ message: inout Message, with resp: ChatResponseStream) {
        switch resp.type {
        case .ping, .message_delta, .content_block_stop:
            return
        case .message_start:
            if let message_resp = resp.message {
                message.id = (message_resp.id != nil) ? message_resp.id! : message.id
                message.finishReason = decode(message_resp.stop_reason)
            }
        case .message_stop:
            message.finishReason = (message.toolCalls != nil) ? .toolCalls : .stop
        case .content_block_start:
            if let contentBlock = resp.content_block {
                switch contentBlock.type {
                case .text:
                    if let text = contentBlock.text {
                        message.contents = [.text(text)]
                    }
                case .tool_use:
                    var toolCall = ToolCall(function: .init(name: contentBlock.name ?? "", arguments: ""))
                    toolCall.id = contentBlock.id ?? toolCall.id
                    if message.toolCalls == nil {
                        message.toolCalls = []
                    }
                    message.toolCalls?.append(toolCall)
                default:
                    break
                }
            }
        case .content_block_delta:
            if let delta = resp.delta {
                switch delta.type {
                case .text_delta:
                    if case .text(let existing) = message.contents?.last {
                        let patched = GenKit.patch(string: existing, with: delta.text) ?? existing
                        message.contents![message.contents!.count-1] = .text(patched)
                    } else if let text = delta.text {
                        message.contents?.append(.text(text))
                    }
                case .input_json_delta:
                    if var existing = message.toolCalls?.last {
                        existing.function.arguments = GenKit.patch(string: existing.function.arguments, with: delta.partial_json) ?? ""
                        message.toolCalls![message.toolCalls!.count-1] = existing
                    }
                default:
                    break
                }
            }
        }
        message.modified = .now
    }
}
