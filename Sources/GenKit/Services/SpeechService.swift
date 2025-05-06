import Foundation

public protocol SpeechService: Sendable {
    func voices() async throws -> [Voice]
    func voiceClone(_ request: SpeechVoiceCloneRequest) async throws -> String

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

public struct SpeechVoiceCloneRequest {
    public var model: String
    public var audio: Data

    public init(model: String, audio: Data) {
        self.model = model
        self.audio = audio
    }
}
