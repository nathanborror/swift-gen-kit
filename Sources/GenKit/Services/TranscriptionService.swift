import Foundation

public protocol TranscriptionService: Sendable {
    func transcribe(_ request: TranscriptionServiceRequest) async throws -> String
}

public struct TranscriptionServiceRequest {
    public var model: Model
    public var file: URL
    public var prompt: String?
    public var language: String?
    public var responseFormat: String?
    public var temperature: Double?
    
    public init(model: Model, file: URL, prompt: String? = nil, language: String? = nil,
                responseFormat: String? = nil, temperature: Double? = nil) {
        self.model = model
        self.file = file
        self.prompt = prompt
        self.language = language
        self.responseFormat = responseFormat
        self.temperature = temperature
    }
}
