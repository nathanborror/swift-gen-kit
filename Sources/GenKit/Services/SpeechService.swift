import Foundation

public protocol SpeechService: Sendable {
    func speak(_ request: SpeechServiceRequest) async throws -> Data
}

public struct SpeechServiceRequest {
    public var voice: String
    public var model: Model
    public var input: String
    public var responseFormat: String?
    public var speed: Double?
    
    public init(voice: String, model: Model, input: String, responseFormat: String? = nil, speed: Double? = nil) {
        self.voice = voice
        self.model = model
        self.input = input
        self.responseFormat = responseFormat
        self.speed = speed
    }
}
