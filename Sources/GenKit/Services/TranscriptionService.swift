import Foundation

public protocol TranscriptionService: Sendable {
    func transcribe(_ request: TranscriptionServiceRequest) async throws -> String
}

public struct TranscriptionServiceRequest {
    public var model: Model
    public var data: Data
    public var prompt: String?
    public var language: String?
    public var responseFormat: String?
    public var temperature: Float?
    
    public init(model: Model, data: Data, prompt: String? = nil, language: String? = nil,
                responseFormat: String? = nil, temperature: Float? = nil) {
        self.model = model
        self.data = data
        self.prompt = prompt
        self.language = language
        self.responseFormat = responseFormat
        self.temperature = temperature
    }
}
