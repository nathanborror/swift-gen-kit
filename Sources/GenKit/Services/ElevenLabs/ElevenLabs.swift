import Foundation
import OSLog
import ElevenLabs

private let logger = Logger(subsystem: "ElevenLabsService", category: "GenKit")

public actor ElevenLabsService {
    
    private var client: ElevenLabsClient
    
    public init(configuration: ElevenLabsClient.Configuration) {
        self.client = ElevenLabsClient(configuration: configuration)
    }
}

extension ElevenLabsService: SpeechService {
    
    public func speak(_ request: SpeechServiceRequest) async throws -> Data {
        try await client.textToSpeech(.init(
            text: request.input,
            model_id: request.model.id.rawValue
        ), voice: request.voice, outputFormat: request.responseFormat)
    }
}

extension ElevenLabsService: ModelService {
    
    public func models() async throws -> [Model] {
        let results = try await client.models()
        return results.map { Model(id: Model.ID($0.modelID), owner: "") }
    }
}
