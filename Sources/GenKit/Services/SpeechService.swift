import Foundation

public protocol SpeechService {
    func speak(request: SpeechServiceRequest) async throws -> Data
}

public struct SpeechServiceRequest {
    public var voice: String
    public var model: String
    public var input: String
    public var responseFormat: String?
    public var speed: Double?
    
    public init(voice: String, model: String, input: String, responseFormat: String? = nil, speed: Double? = nil) {
        self.voice = voice
        self.model = model
        self.input = input
        self.responseFormat = responseFormat
        self.speed = speed
    }
}
