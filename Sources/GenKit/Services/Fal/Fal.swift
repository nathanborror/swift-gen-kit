import Foundation
import OSLog
import Fal

private let logger = Logger(subsystem: "FalService", category: "GenKit")

public actor FalService {
    
    private var client: Fal.Client
    private let session: URLSession

    public init(session: URLSession? = nil, host: URL? = nil, apiKey: String) {
        self.client = .init(session: session, host: host, apiKey: apiKey)
        self.session = session ?? URLSession(configuration: .default)
    }
}

extension FalService: ImageService {
    
    public func imagine(_ request: ImagineServiceRequest) async throws -> [Data] {
        let query = Fal.TextToImageRequest(
            prompt: request.prompt,
            num_images: request.n,
            output_format: .png // TODO: Use response_format
        )
        let result = try await client.textToImage(query, model: request.model.id)

        return try await withThrowingTaskGroup(of: Data?.self) { group in
            for image in result.images {
                group.addTask {
                    guard let url = URL(string: image.url) else { return nil }
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

extension FalService: SpeechService {

    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        let query = Fal.TextToSpeechRequest(
            text: request.input
        )
        let result = try await client.textToSpeech(query, model: request.model.id)
        let (data, _) = try await session.data(from: result.audio.url)
        return data
    }

    public func voices() async throws -> [Voice] {
        throw ServiceError.notImplemented
    }

    public func voiceClone(_ request: SpeechVoiceCloneRequest) async throws -> String {
        let query = Fal.VoiceCloneRequest(
            audio_url: request.audio.base64EncodedString()
        )
        let result = try await client.voiceClone(query, model: request.model)
        return result.custom_voice_id
    }
}

extension FalService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(id: $0.id, name: $0.name, owner: $0.owner)
        }
    }
}
