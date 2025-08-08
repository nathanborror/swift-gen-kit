import Foundation
import OSLog
import OpenAI
import SharedKit

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public actor OpenAIService {

    private var client: OpenAI.Client
    private let session: URLSession

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
        self.session = session ?? URLSession(configuration: .default)
    }
}

// MARK: - Services

extension OpenAIService: ChatService {

    public func completion(_ request: ChatServiceRequest) async throws -> Message {
            let req = ChatRequest(
                messages: encode(messages: request.messages),
                model: request.model.id,
                reasoning_effort: request.options["reasoning_effort"]?.stringValue.flatMap(OpenAI.ChatRequest.ReasoningEffort.init),
                temperature: request.options["temperature"]?.doubleValue,
                tools: encode(request.tools),
                tool_choice: encode(request.toolChoice),
                verbosity: request.options["verbosity"]?.stringValue.flatMap(OpenAI.ChatRequest.Verbosity.init)
            )
            let resp = try await client.chatCompletions(req)
            guard let message = decode(resp) else {
                throw ChatServiceError.responseError("Missing response choice")
            }
            return message
        }

        public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
            let req = OpenAI.ChatRequest(
                messages: encode(messages: request.messages),
                model: request.model.id,
                reasoning_effort: request.options["reasoning_effort"]?.stringValue.flatMap(OpenAI.ChatRequest.ReasoningEffort.init),
                stream: true,
                temperature: request.options["temperature"]?.doubleValue,
                tools: encode(request.tools),
                tool_choice: encode(request.toolChoice),
                verbosity: request.options["verbosity"]?.stringValue.flatMap(OpenAI.ChatRequest.Verbosity.init)
            )
            var message = Message(role: .assistant)
            for try await resp in try client.chatCompletionsStream(req) {
                patchMessage(&message, with: resp)
                try await update(message)
            }
        }
}

extension OpenAIService: EmbeddingService {

    public func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double] {
        let req = OpenAI.EmbeddingsRequest(
            input: request.input,
            model: request.model.id
        )
        let result = try await client.embeddings(req)
        return result.data.first?.embedding ?? []
    }
}

extension OpenAIService: ModelService {

    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { decode($0) }
    }
}

extension OpenAIService: ImageService {

    public func imagine(_ request: ImagineServiceRequest) async throws -> [Data] {
        let req = OpenAI.ImageRequest(
            prompt: request.prompt,
            model: request.model.id,
            n: request.n,
            size: .size_1024x1024
        )
        let result = try await client.imagesGenerations(req)

        // HACK: Wait for a second for the images to be available on OpenAI's CDN. Without this the URLs in the
        // result may fail.
        let seconds = 1
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

        return try await withThrowingTaskGroup(of: Data?.self) { group in
            for image in result.data {
                group.addTask {
                    guard let imageURL = image.url, let url = URL(string: imageURL) else { return nil }
                    let (data, _) = try await self.session.data(from: url)
                    return data
                }
            }
            var downloadedImages: [Data] = []
            for try await data in group {
                if let data {
                    downloadedImages.append(data)
                }
            }
            return downloadedImages
        }
    }
}

extension OpenAIService: TranscriptionService {

    public func transcribe(_ request: TranscriptionServiceRequest) async throws -> String {
        let req = OpenAI.TranscriptionRequest(
            file: request.file,
            model: request.model.id,
            language: request.language,
            prompt: request.prompt,
            response_format: (request.responseFormat != nil) ? .init(rawValue: request.responseFormat!) : nil,
            temperature: request.temperature
        )
        let result = try await client.transcriptions(req)
        return result.text
    }
}

extension OpenAIService: SpeechService {

    public func voices() async throws -> [Voice] {
        return ["alloy", "ash", "ballad", "coral", "echo", "fable", "onyx", "nova", "sage", "shimmer", "verse"].map {
            Voice(id: $0, name: nil)
        }
    }

    public func voiceClone(_ request: SpeechVoiceCloneRequest) async throws -> String {
        throw ServiceError.notImplemented
    }

    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        let req = OpenAI.SpeechRequest(
            model: request.model.id,
            input: request.input,
            voice: .init(rawValue: request.voice) ?? .alloy,
            response_format: (request.responseFormat != nil) ? .init(rawValue: request.responseFormat!) : nil,
            speed: request.speed
        )
        return try await client.speech(req)
    }
}

// MARK: - Encoders

extension OpenAIService {

    private func encode(messages: [Message]) -> [OpenAI.ChatRequest.Message] {
        messages.map { message in
            OpenAI.ChatRequest.Message(
                content: encode(message.contents, role: message.role),
                role: encode(message.role),
                name: message.name,
                tool_calls: encode(message.toolCalls),
                tool_call_id: message.toolCallID
            )
        }
    }

    private func encode(_ contents: [Message.Content]?, role: Message.Role) -> [OpenAI.ChatRequest.Message.Content]? {
        contents?.map {
            switch $0 {
            case .text(let text):
                return .init(type: "text", text: text)
            case .image(let image):
                guard role == .user else {
                    return nil
                }
                guard let data = try? Data(contentsOf: image.url) else {
                    return nil
                }
                return .init(type: "image_url", image_url: .init(url: "data:\(image.format.rawValue);base64,\(data.base64EncodedString())"))
            case .audio(let audio):
                guard role == .user else {
                    return nil
                }
                guard let data = try? Data(contentsOf: audio.url) else {
                    return nil
                }
                return .init(type: "input_audio", input_audio: .init(data: data.base64EncodedString(), format: audio.format.rawValue))
            case .json(let json):
                return .init(type: "text", text: json.object)
            case .file(let file):
                guard
                    let data = try? Data(contentsOf: .documentsDirectory.appending(path: file.path)),
                    let content = String(data: data, encoding: .utf8) else { return nil }
                return .init(type: "text", text: """
                    ```\(file.mimetype.preferredFilenameExtension ?? "txt") \(file.path)
                    \(content)
                    ```
                    """)
            }
        }.compactMap({$0})
    }

    private func encode(_ role: Message.Role) -> OpenAI.ChatRequest.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
        }
    }

    private func encode(_ toolCalls: [ToolCall]?) -> [OpenAI.ChatRequest.Message.ToolCall]? {
        toolCalls?.map { toolCall in
            OpenAI.ChatRequest.Message.ToolCall(
                id: toolCall.id,
                type: toolCall.type,
                function: encode(toolCall.function),
                custom: encode(toolCall.custom)
            )
        }
    }

    private func encode(_ functionCall: ToolCall.Function?) -> OpenAI.ChatRequest.Message.ToolCall.Function? {
        guard let functionCall else { return nil }
        return .init(name: functionCall.name, arguments: functionCall.arguments)
    }

    private func encode(_ customCall: ToolCall.Custom?) -> OpenAI.ChatRequest.Message.ToolCall.Custom? {
        guard let customCall else { return nil }
        return .init(name: customCall.name, input: customCall.input)
    }

    private func encode(_ tools: [Tool]) -> [OpenAI.ChatRequest.Tool]? {
        guard !tools.isEmpty else { return nil }
        return tools.map { tool in
            OpenAI.ChatRequest.Tool(
                type: tool.type.rawValue,
                function: encode(tool.function),
                custom: encode(tool.custom)
            )
        }
    }

    private func encode(_ function: Tool.Function?) -> OpenAI.ChatRequest.Tool.Function? {
        guard let function else { return nil }
        return .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters
        )
    }

    private func encode(_ custom: Tool.Custom?) -> OpenAI.ChatRequest.Tool.Custom? {
        guard let custom else { return nil }
        return .init(
            name: custom.name,
            description: custom.description,
            format: (custom.format != nil) ? .init(
                type: custom.format!.type,
                grammar: (custom.format!.grammar != nil) ? .init(
                    definition: custom.format!.grammar!.definition,
                    syntax: custom.format!.grammar!.syntax
                ) : nil
            ) : nil
        )
    }

    private func encode(_ toolChoice: Tool?) -> OpenAI.ChatRequest.ToolChoice? {
        if let function = toolChoice?.function {
            return .tool(.init(function: function.name))
        }
        if let custom = toolChoice?.custom {
            return .tool(.init(custom: custom.name))
        }
        return nil
    }

    private func encode(responseFormat: String?) -> OpenAI.TranslationRequest.ResponseFormat? {
        guard let responseFormat else { return nil }
        return .init(rawValue: responseFormat)
    }

    // Speech

    private func encode(responseFormat: String?) throws -> OpenAI.SpeechRequest.ResponseFormat? {
        guard let responseFormat else { return nil }
        switch responseFormat {
        case "mp3":
            return .mp3
        case "opus":
            return .opus
        case "aac":
            return .aac
        case "flac":
            return .flac
        default:
            throw ServiceError.unsupportedResponseFormat
        }
    }
}

// MARK: - Decoders

// MARK: - Decoders

extension OpenAIService {

    private func decode(_ resp: OpenAI.ChatResponse) -> Message? {
        guard let choice = resp.choices.first else { return nil }
        return Message(
            role: decode(choice.message.role),
            contents: [decode(choice.message.content)].compactMap { $0 },
            toolCalls: choice.message.tool_calls?.map { decode($0) },
            finishReason: decode(choice.finish_reason)
        )
    }
    
    private func decode(_ role: String) -> Message.Role {
        switch role {
        case "system":
            return .system
        case "user":
            return .user
        case "assistant":
            return .assistant
        case "tool":
            return .tool
        default:
            return .assistant
        }
    }
    
    private func decode(_ content: String?) -> Message.Content? {
        guard let content else { return nil }
        return .text(content)
    }
    
    private func decode(_ reason: String?) -> Message.FinishReason? {
        switch reason {
        case "stop":
            return .stop
        case "length":
            return .length
        case "tool_calls":
            return .toolCalls
        case "content_filter":
            return .contentFilter
        default:
            return nil
        }
    }
    
    private func decode(_ resp: OpenAI.ChatResponse.Choice.Message.ToolCall) -> ToolCall {
        ToolCall(
            index: resp.index,
            id: resp.id ?? "",
            type: resp.type ?? "function",
            function: (resp.function != nil) ? .init(
                name: resp.function!.name ?? "",
                arguments: resp.function!.arguments
            ) : nil,
            custom: (resp.custom != nil) ? .init(
                name: resp.custom!.name ?? "",
                input: resp.custom!.input
            ) : nil
        )
    }
    
    private func decode(_ model: OpenAI.Model) -> Model {
        Model(
            id: .init(model.id),
            name: model.id,
            owner: model.owned_by ?? "openai"
        )
    }
    
    private func patchMessage(_ message: inout Message, with resp: OpenAI.ChatStreamResponse) {
        guard let choice = resp.choices.first else { return }

        if case .text(let text) = message.contents?.last {
            if let patched = GenKit.patch(string: text, with: choice.delta.content) {
                message.contents = [.text(patched)]
            }
        } else if let text = choice.delta.content {
            message.contents = [.text(text)]
        }
        message.finishReason = decode(choice.finish_reason)
        message.modified = .now

        // Add new tool calls and patch the last tool call being streamed in
        if let toolCalls = choice.delta.tool_calls {
            if message.toolCalls == nil {
                message.toolCalls = []
            }
            for toolCall in toolCalls {
                if var existing = message.toolCalls?.first(where: { $0.index == toolCall.index }) {
                    if let function = existing.function {
                        existing.function!.arguments = GenKit.patch(string: function.arguments, with: toolCall.function?.arguments) ?? ""
                    }
                    if let custom = existing.custom {
                        existing.custom!.input = GenKit.patch(string: custom.input, with: toolCall.custom?.input) ?? ""
                    }
                    message.toolCalls![existing.index!] = existing
                } else {
                    message.toolCalls?.append(decode(toolCall))
                }
            }
        }
    }
}
