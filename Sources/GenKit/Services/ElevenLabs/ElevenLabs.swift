import Foundation
import OSLog
import ElevenLabs

private let logger = Logger(subsystem: "ElevenLabsService", category: "GenKit")

public final class ElevenLabsService {
    
    private var client: ElevenLabsClient
    
    public init(configuration: ElevenLabsClient.Configuration) {
        self.client = ElevenLabsClient(configuration: configuration)
        logger.info("ElevenLabs Service: \(self.client.configuration.host.absoluteString)")
    }
}

extension ElevenLabsService: SpeechService {
    
    public func speak(request: SpeechServiceRequest) async throws -> Data {
        let query = TextToSpeechQuery(text: request.input)
        return try await client.textToSpeech(query, voice: request.voice, outputFormat: try encode(responseFormat: request.responseFormat))
    }
}

extension ElevenLabsService: ModelService {
    
    public func models() async throws -> [Model] {
        let results = try await client.models()
        return results.map { Model(id: $0.modelID, owner: "") }
    }
}
