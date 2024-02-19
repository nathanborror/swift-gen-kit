import Foundation
import ElevenLabs

extension ElevenLabsService {
    
    func encode(responseFormat: SpeechServiceRequest.ResponseFormat?) throws -> String? {
        guard let responseFormat else { return nil }
        switch responseFormat {
        case .mp3:
            return "mp3_44100_128"
        case .opus:
            throw ServiceError.unsupportedResponseFormat
        case .aac:
            throw ServiceError.unsupportedResponseFormat
        case .flac:
            throw ServiceError.unsupportedResponseFormat
        case .custom(let string):
            return string
        }
    }
}
