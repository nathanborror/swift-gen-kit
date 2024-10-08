import Foundation

public protocol SpeechService: Sendable {
    func speak(_ request: SpeechServiceRequest) async throws -> Data
}

public struct SpeechServiceRequest {
    public var voice: String
    public var model: Model
    public var input: String
    public var responseFormat: ResponseFormat?
    public var speed: Float?
    
    public enum ResponseFormat {
        case mp3
        case opus
        case aac
        case flac
        case custom(String)
    }
    
    public init(voice: String, model: Model, input: String, responseFormat: ResponseFormat? = nil, speed: Float? = nil) {
        self.voice = voice
        self.model = model
        self.input = input
        self.responseFormat = responseFormat
        self.speed = speed
    }
}
