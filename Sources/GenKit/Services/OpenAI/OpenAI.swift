import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public actor OpenAIService {
    
    private var client: OpenAI.Client
    private let session: URLSession

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
        self.session = session ?? URLSession(configuration: .default)
    }
}

extension OpenAIService: ChatService {
    
    public func completion(_ request: ChatServiceRequest) async throws -> Message {
        let req = ChatRequest(
            messages: encode(messages: request.messages),
            model: request.model.id,
            temperature: request.temperature,
            tools: encode(request.tools),
            tool_choice: encode(request.toolChoice)
        )
        let resp = try await client.chatCompletions(req)
        guard let message = Message(resp) else {
            throw ChatServiceError.responseError("Missing response choice")
        }
        return message
    }
    
    public func completionStream(_ request: ChatServiceRequest, update: (Message) async throws -> Void) async throws {
        let req = OpenAI.ChatRequest(
            messages: encode(messages: request.messages),
            model: request.model.id,
            stream: true,
            temperature: request.temperature,
            tools: encode(request.tools),
            tool_choice: encode(request.toolChoice)
        )
        var message = Message(role: .assistant)
        for try await resp in try client.chatCompletionsStream(req) {
            message.patch(with: resp)
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
        return result.data.map { .init($0) }
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
