import Foundation
import OSLog
import ElevenLabs

private let logger = Logger(subsystem: "ElevenLabsService", category: "GenKit")

public actor ElevenLabsService {

    private var client: ElevenLabs.Client

    public init(apiKey: String) {
        self.client = .init(apiKey: apiKey)
    }
}

extension ElevenLabsService: SpeechService {

    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        try await client.textToSpeech(.init(
            text: request.input,
            model_id: request.model.id
        ), voice: request.voice, outputFormat: request.responseFormat)
    }
}

extension ElevenLabsService: ModelService {

    public func models() async throws -> [Model] {
        let results = try await client.models()
        return results.map { Model(id: $0.model_id, owner: "elevenlabs") }
    }
}
