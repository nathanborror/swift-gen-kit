// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Codable, Identifiable, Sendable {
    public var id: ServiceID
    public var name: String
    public var credentials: Credentials?
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
        case host(URL)
        case token(String)
        
        var host: URL? {
            guard case .host(let url) = self else { return nil }
            return url
        }
        
        var token: String? {
            guard case .token(let str) = self else { return nil }
            return str
        }
    }
    
    public init(id: ServiceID, name: String, credentials: Credentials? = nil, models: [Model] = [],
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
    
    public func modelService() throws -> ModelService {
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return AnthropicService(configuration: .init(token: token))
        case .elevenLabs:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return ElevenLabsService(configuration: .init(token: token))
        case .google:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return GoogleService(configuration: .init(token: token))
        case .groq:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token, host: .init(string: "https://api.groq.com/openai/v1")!))
        case .mistral:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return MistralService(configuration: .init(token: token))
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return PerplexityService(configuration: .init(token: token))
        case .fal:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return FalService(configuration: .init(token: token))
        }
    }
    
    public func chatService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return AnthropicService(configuration: .init(token: token))
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return GoogleService(configuration: .init(token: token))
        case .groq:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token, host: .init(string: "https://api.groq.com/openai/v1")!))
        case .mistral:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return MistralService(configuration: .init(token: token))
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return PerplexityService(configuration: .init(token: token))
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func imageService() throws -> ImageService {
        guard preferredImageModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            throw ServiceError.unsupportedService
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            throw ServiceError.unsupportedService
        case .mistral:
            throw ServiceError.unsupportedService
        case .ollama:
            throw ServiceError.unsupportedService
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            throw ServiceError.unsupportedService
        case .fal:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return FalService(configuration: .init(token: token))
        }
    }
    
    public func embeddingService() throws -> EmbeddingService {
        guard preferredEmbeddingModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            throw ServiceError.unsupportedService
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token, host: .init(string: "https://api.groq.com/openai/v1")!))
        case .mistral:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return MistralService(configuration: .init(token: token))
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            throw ServiceError.unsupportedService
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func transcriptionService() throws -> TranscriptionService {
        guard preferredTranscriptionModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            throw ServiceError.unsupportedService
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            throw ServiceError.unsupportedService
        case .mistral:
            throw ServiceError.unsupportedService
        case .ollama:
            throw ServiceError.unsupportedService
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            throw ServiceError.unsupportedService
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func toolService() throws -> ToolService {
        guard preferredToolModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return AnthropicService(configuration: .init(token: token))
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token, host: .init(string: "https://api.groq.com/openai/v1")!))
        case .mistral:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return MistralService(configuration: .init(token: token))
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return PerplexityService(configuration: .init(token: token))
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func visionService() throws -> VisionService {
        guard preferredVisionModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return AnthropicService(configuration: .init(token: token))
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            throw ServiceError.unsupportedService
        case .mistral:
            throw ServiceError.unsupportedService
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            throw ServiceError.unsupportedService
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func speechService() throws -> SpeechService {
        guard preferredSpeechModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            throw ServiceError.unsupportedService
        case .elevenLabs:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return ElevenLabsService(configuration: .init(token: token))
        case .google:
            throw ServiceError.unsupportedService
        case .groq:
            throw ServiceError.unsupportedService
        case .mistral:
            throw ServiceError.unsupportedService
        case .ollama:
            throw ServiceError.unsupportedService
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            throw ServiceError.unsupportedService
        case .fal:
            throw ServiceError.unsupportedService
        }
    }
    
    public func summarizationService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        guard let credentials else {
            throw ServiceError.missingCredentials
        }
        switch id {
        case .anthropic:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return AnthropicService(configuration: .init(token: token))
        case .elevenLabs:
            throw ServiceError.unsupportedService
        case .google:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return GoogleService(configuration: .init(token: token))
        case .groq:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token, host: .init(string: "https://api.groq.com/openai/v1")!))
        case .mistral:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return MistralService(configuration: .init(token: token))
        case .ollama:
            guard let host = credentials.host else { throw ServiceError.missingCredentials }
            return OllamaService(configuration: .init(host: host))
        case .openAI:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return OpenAIService(configuration: .init(token: token))
        case .perplexity:
            guard let token = credentials.token else { throw ServiceError.missingCredentials }
            return PerplexityService(configuration: .init(token: token))
        case .fal:
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
