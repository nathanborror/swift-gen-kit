import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public final class OpenAIService: ChatService {
    
    private var client: OpenAIClient
    
    public init(configuration: OpenAIClient.Configuration) {
        self.client = OpenAIClient(configuration: configuration)
        logger.info("OpenAI Service: \(self.client.configuration.host.absoluteString)")
    }
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let query = ChatQuery(
            model: request.model,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice)
        )
        let result = try await client.chats(query: query)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let query = ChatQuery(
            model: request.model,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice)
        )
        let stream: AsyncThrowingStream<ChatStreamResult, Error> = client.chatsStream(query: query)
        for try await result in stream {
            let message = decode(result: result)
            await delta(message)
        }
    }
}

extension OpenAIService: EmbeddingService {
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let query = EmbeddingsQuery(model: model, input: input)
        let result = try await client.embeddings(query: query)
        return result.data.first?.embedding ?? []
    }
}

extension OpenAIService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.data.map { Model(id: $0.id, owner: $0.ownedBy) }
    }
}

extension OpenAIService: ImageService {
    
    public func imagine(request: ImagineServiceRequest) async throws -> [Data] {
        let query = ImagesQuery(
            prompt: request.prompt,
            model: request.model,
            n: request.n,
            size: request.size
        )
        let result = try await client.images(query: query)
        if let data = result.data {
            return try data.map {
                guard let url = $0.url else { return nil }
                let remoteURL = URL(string: url)!
                return try Data(contentsOf: remoteURL)
            }.compactMap { $0 }
        } 
        throw ServiceError.missingImageData
    }
}

extension OpenAIService: TranscriptionService {
    
    public func transcribe(request: TranscriptionServiceRequest) async throws -> String {
        let query = AudioTranscriptionQuery(
            file: request.data,
            model: request.model,
            prompt: request.prompt,
            temperature: request.temperature,
            language: request.language,
            responseFormat: encode(responseFormat: request.responseFormat)
        )
        let result = try await client.audioTranscriptions(query: query)
        return result.text
    }
}
