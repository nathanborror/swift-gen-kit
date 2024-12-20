// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Codable, Identifiable, Sendable {
    public var id: ServiceID
    public var name: String
    public var host: String
    public var token: String
    public var models: [Model]
    public var status: Status
    
    public var preferredChatModel: Model.ID?
    public var preferredImageModel: Model.ID?
    public var preferredEmbeddingModel: Model.ID?
    public var preferredTranscriptionModel: Model.ID?
    public var preferredToolModel: Model.ID?
    public var preferredVisionModel: Model.ID?
    public var preferredSpeechModel: Model.ID?
    public var preferredSummarizationModel: Model.ID?
    
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
    
    public enum Status: String, Codable, Sendable {
        case ready
        case missingHost
        case missingToken
        case unknown
    }
    
    public init(id: ServiceID, name: String, host: String = "", token: String = "", models: [Model] = [],
                preferredChatModel: Model.ID? = nil, preferredImageModel: Model.ID? = nil,
                preferredEmbeddingModel: Model.ID? = nil, preferredTranscriptionModel: Model.ID? = nil,
                preferredToolModel: Model.ID? = nil, preferredVisionModel: Model.ID? = nil,
                preferredSpeechModel: Model.ID? = nil, preferredSummarizationModel: Model.ID? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.token = token
        self.models = models
        self.status = .unknown
        
        self.preferredChatModel = preferredChatModel
        self.preferredImageModel = preferredImageModel
        self.preferredEmbeddingModel = preferredEmbeddingModel
        self.preferredTranscriptionModel = preferredTranscriptionModel
        self.preferredToolModel = preferredToolModel
        self.preferredVisionModel = preferredVisionModel
        self.preferredSpeechModel = preferredSpeechModel
        self.preferredSummarizationModel = preferredSummarizationModel
    }
    
    var hostURL: URL? {
        URL(string: host)
    }
}

extension Service {
    
    public func anthropic() -> AnthropicService {
        AnthropicService(configuration: .init(host: hostURL, token: token))
    }
    
    public func elevenLabs() -> ElevenLabsService {
        ElevenLabsService(token)
    }
    
    public func fal() -> FalService {
        FalService(configuration: .init(host: hostURL, token: token))
    }
    
    public func google() -> GoogleService {
        GoogleService(configuration: .init(host: hostURL, token: token))
    }
    
    public func groq() -> OpenAIService {
        OpenAIService(configuration: .init(host: hostURL, token: token))
    }
    
    public func mistral() -> MistralService {
        MistralService(configuration: .init(host: hostURL, token: token))
    }
    
    public func ollama() -> OllamaService {
        OllamaService(configuration: .init(host: hostURL))
    }
    
    public func openAI() -> OpenAIService {
        OpenAIService(configuration: .init(host: hostURL, token: token))
    }
    
    public func perplexity() -> PerplexityService {
        PerplexityService(configuration: .init(host: hostURL, token: token))
    }
    
    public func modelService() -> ModelService {
        switch id {
        case .anthropic:
            anthropic()
        case .elevenLabs:
            elevenLabs()
        case .fal:
            fal()
        case .google:
            google()
        case .groq:
            groq()
        case .mistral:
            mistral()
        case .ollama:
            ollama()
        case .openAI:
            openAI()
        case .perplexity:
            perplexity()
        }
    }
    
    public func chatService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return anthropic()
        case .google:
            return google()
        case .groq:
            return groq()
        case .mistral:
            return mistral()
        case .ollama:
            return ollama()
        case .openAI:
            return openAI()
        case .perplexity:
            return perplexity()
        case .elevenLabs, .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func imageService() throws -> ImageService {
        guard preferredImageModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .fal:
            return fal()
        case .openAI:
            return openAI()
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
            return groq()
        case .mistral:
            return mistral()
        case .ollama:
            return ollama()
        case .openAI:
            return openAI()
        case .anthropic, .elevenLabs, .fal, .google, .perplexity:
            throw ServiceError.unsupportedService
        }
    }
    
    public func transcriptionService() throws -> TranscriptionService {
        guard preferredTranscriptionModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .groq:
            return groq()
        case .openAI:
            return openAI()
        case .anthropic, .elevenLabs, .fal, .google, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }
    
    public func visionService() throws -> VisionService {
        guard preferredVisionModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return anthropic()
        case .groq:
            return groq()
        case .ollama:
            return ollama()
        case .openAI:
            return openAI()
        case .elevenLabs, .fal, .google, .mistral, .perplexity:
            throw ServiceError.unsupportedService
        }
    }
    
    public func speechService() throws -> SpeechService {
        guard preferredSpeechModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .elevenLabs:
            return elevenLabs()
        case .groq:
            return groq()
        case .openAI:
            return openAI()
        case .anthropic, .google, .fal, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }
    
    public func summarizationService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch id {
        case .anthropic:
            return anthropic()
        case .google:
            return google()
        case .groq:
            return groq()
        case .mistral:
            return mistral()
        case .ollama:
            return ollama()
        case .openAI:
            return openAI()
        case .perplexity:
            return perplexity()
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
