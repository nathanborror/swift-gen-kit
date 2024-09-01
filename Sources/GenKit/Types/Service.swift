// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Codable, Identifiable, Sendable {
    public var id: ServiceID
    public var name: String
    public var credentials: Credentials
    public var models: [Model]
    
    public var preferredChatModel: String?
    public var preferredImageModel: String?
    public var preferredEmbeddingModel: String?
    public var preferredTranscriptionModel: String?
    public var preferredToolModel: String?
    public var preferredVisionModel: String?
    public var preferredSpeechModel: String?
    public var preferredSummarizationModel: String?
    
    public enum ServiceID: String, Codable, Sendable {
        case anthropic
        case elevenLabs
        case fal
        case google
        case groq
        case mistral
        case ollama
        case openAI
        case perplexity
    }
    
    public enum Credentials: Codable, Sendable {
        case host(URL?)
        case token(String?)
        case hostAndToken(URL?, String?)
        
        var host: URL? {
            if case .host(let host) = self { return host }
            if case .hostAndToken(let host, _) = self { return host }
            return nil
        }
        
        var token: String? {
            if case .token(let token) = self { return token }
            if case .hostAndToken(_, let token) = self { return token }
            return nil
        }
    }
    
    public init(id: ServiceID, name: String, credentials: Credentials = .hostAndToken(nil, nil), models: [Model] = [],
                preferredChatModel: String? = nil, preferredImageModel: String? = nil,
                preferredEmbeddingModel: String? = nil, preferredTranscriptionModel: String? = nil,
                preferredToolModel: String? = nil, preferredVisionModel: String? = nil,
                preferredSpeechModel: String? = nil, preferredSummarizationModel: String? = nil) {
        self.id = id
        self.name = name
        self.credentials = credentials
        self.models = models
        
        self.preferredChatModel = preferredChatModel
        self.preferredImageModel = preferredImageModel
        self.preferredEmbeddingModel = preferredEmbeddingModel
        self.preferredTranscriptionModel = preferredTranscriptionModel
        self.preferredToolModel = preferredToolModel
        self.preferredVisionModel = preferredVisionModel
        self.preferredSpeechModel = preferredSpeechModel
        self.preferredSummarizationModel = preferredSummarizationModel
    }
}

extension Service {
    
    /// Returns valid credentials used to connect to a Service. If the host is nil then the Service uses the
    /// default host located in the service package.
    public func hasValidCredentials() throws -> (URL?, String?){
        switch credentials {
        case let .host(url):
            return (url, nil)
        case let .token(token):
            if token == nil {
                throw ServiceError.missingServiceToken
            }
            return (nil, token)
        case let .hostAndToken(url, token):
            if token == nil {
                throw ServiceError.missingServiceToken
            }
            return (url, token)
        }
    }
    
    public func anthropic() throws -> AnthropicService {
        let (host, token) = try hasValidCredentials()
        return AnthropicService(configuration: .init(host: host, token: token!))
    }
    
    public func openAI() throws -> OpenAIService {
        let (host, token) = try hasValidCredentials()
        return OpenAIService(configuration: .init(host: host, token: token!))
    }
    
    public func google() throws -> GoogleService {
        let (host, token) = try hasValidCredentials()
        return GoogleService(configuration: .init(host: host, token: token!))
    }
    
    public func mistral() throws -> MistralService {
        let (host, token) = try hasValidCredentials()
        return MistralService(configuration: .init(host: host, token: token!))
    }
    
    public func groq() throws -> OpenAIService {
        let (host, token) = try hasValidCredentials()
        return OpenAIService(configuration: .init(host: host, token: token!))
    }
    
    public func elevenLabs() throws -> ElevenLabsService {
        let (host, token) = try hasValidCredentials()
        return ElevenLabsService(configuration: .init(host: host, token: token!))
    }
    
    public func ollama() throws -> OllamaService {
        let (host, _) = try hasValidCredentials()
        return OllamaService(configuration: .init(host: host))
    }
    
    public func perplexity() throws -> PerplexityService {
        let (host, token) = try hasValidCredentials()
        return PerplexityService(configuration: .init(host: host, token: token!))
    }
    
    public func fal() throws -> FalService {
        let (host, token) = try hasValidCredentials()
        return FalService(configuration: .init(host: host, token: token!))
    }
    
    public func modelService() throws -> ModelService {
        switch id {
        case .anthropic:
            return try anthropic()
        case .elevenLabs:
            return try elevenLabs()
        case .google:
            return try google()
        case .groq:
            return try groq()
        case .mistral:
            return try mistral()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .perplexity:
            return try perplexity()
        case .fal:
            return try fal()
        }
    }
    
    public func chatService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return try anthropic()
        case .google:
            return try google()
        case .groq:
            return try groq()
        case .mistral:
            return try mistral()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .perplexity:
            return try perplexity()
        case .elevenLabs, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func imageService() throws -> ImageService {
        guard preferredImageModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .openAI:
            return try openAI()
        case .fal:
            return try fal()
        case .anthropic, .elevenLabs, .google, .groq, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }
    
    public func embeddingService() throws -> EmbeddingService {
        guard preferredEmbeddingModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .groq:
            return try groq()
        case .mistral:
            return try mistral()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .anthropic, .elevenLabs, .google, .perplexity, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func transcriptionService() throws -> TranscriptionService {
        guard preferredTranscriptionModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .groq:
            return try groq()
        case .openAI:
            return try openAI()
        case .anthropic, .elevenLabs, .google, .mistral, .ollama, .perplexity, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func toolService() throws -> ToolService {
        guard preferredToolModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return try anthropic()
        case .groq:
            return try groq()
        case .mistral:
            return try mistral()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .perplexity:
            return try perplexity()
        case .elevenLabs, .google, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func visionService() throws -> VisionService {
        guard preferredVisionModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return try anthropic()
        case .groq:
            return try groq()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .elevenLabs, .google, .mistral, .perplexity, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func speechService() throws -> SpeechService {
        guard preferredSpeechModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .elevenLabs:
            return try elevenLabs()
        case .groq:
            return try groq()
        case .openAI:
            return try openAI()
        case .anthropic, .google, .mistral, .ollama, .perplexity, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func summarizationService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return try anthropic()
        case .google:
            return try google()
        case .groq:
            return try groq()
        case .mistral:
            return try mistral()
        case .ollama:
            return try ollama()
        case .openAI:
            return try openAI()
        case .perplexity:
            return try perplexity()
        case .elevenLabs, .fal:
            throw ServiceError.unsupportedService
        }
    }
}

extension Service {
    
    public var supportsChats: Bool {
        preferredChatModel != nil
    }
    
    public var supportsImages: Bool {
        preferredImageModel != nil
    }
    
    public var supportsEmbeddings: Bool {
        preferredEmbeddingModel != nil
    }
    
    public var supportsTranscriptions: Bool {
        preferredTranscriptionModel != nil
    }
    
    public var supportsTools: Bool {
        preferredToolModel != nil
    }
    
    public var supportsVision: Bool {
        preferredVisionModel != nil
    }
    
    public var supportsSpeech: Bool {
        preferredSpeechModel != nil
    }
    
    public var supportsSummarization: Bool {
        preferredSummarizationModel != nil
    }
}

extension Service {
    
    public mutating func applyPreferredModels(_ service: Service) {
        self.preferredChatModel = service.preferredChatModel
        self.preferredImageModel = service.preferredImageModel
        self.preferredEmbeddingModel = service.preferredEmbeddingModel
        self.preferredTranscriptionModel = service.preferredTranscriptionModel
        self.preferredToolModel = service.preferredToolModel
        self.preferredVisionModel = service.preferredVisionModel
        self.preferredSpeechModel = service.preferredSpeechModel
        self.preferredSummarizationModel = service.preferredSummarizationModel
    }
}
