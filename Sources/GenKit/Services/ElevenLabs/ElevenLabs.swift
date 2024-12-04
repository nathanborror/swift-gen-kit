import Foundation
import OSLog
import ElevenLabs

private let logger = Logger(subsystem: "ElevenLabsService", category: "GenKit")

public actor ElevenLabsService {
    
    private var client: ElevenLabs.Client
    
    public init(_ apiKey: String) {
        self.client = .init(apiKey: apiKey)
    }
}

extension ElevenLabsService: SpeechService {
    
    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        let req = TextToSpeechRequest(
            text: request.input,
            model_id: request.model.id.rawValue
        )
        return try await client.textToSpeech(req, voice: request.voice, outputFormat: try encode(responseFormat: request.responseFormat))
    }
}

extension ElevenLabsService: ModelService {
    
    public func models() async throws -> [Model] {
        let results = try await client.models()
        return results.map { Model(id: Model.ID($0.model_id), owner: "elevenlabs") }
    }
}
