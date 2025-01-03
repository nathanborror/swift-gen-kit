// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var host: String
    public var token: String
    public var models: [Model]
    public var status: Status

    public var preferredChatModel: String?
    public var preferredImageModel: String?
    public var preferredEmbeddingModel: String?
    public var preferredTranscriptionModel: String?
    public var preferredSpeechModel: String?
    public var preferredSummarizationModel: String?

    public enum ServiceID: String, Codable, Hashable, Sendable {
        case anthropic
        case elevenLabs
        case fal
        case groq
        case mistral
        case ollama
        case openAI
        case perplexity
    }

    public enum Status: String, Codable, Hashable, Sendable {
        case ready
        case missingHost
        case missingToken
        case unknown
    }

    public init(id: ServiceID, name: String, host: String = "", token: String = "", models: [Model] = [],
                preferredChatModel: String? = nil, preferredImageModel: String? = nil,
                preferredEmbeddingModel: String? = nil, preferredTranscriptionModel: String? = nil,
                preferredSpeechModel: String? = nil, preferredSummarizationModel: String? = nil) {
        self.id = id.rawValue
        self.name = name
        self.host = host
        self.token = token
        self.models = models
        self.status = .unknown

        self.preferredChatModel = preferredChatModel
        self.preferredImageModel = preferredImageModel
        self.preferredEmbeddingModel = preferredEmbeddingModel
        self.preferredTranscriptionModel = preferredTranscriptionModel
        self.preferredSpeechModel = preferredSpeechModel
        self.preferredSummarizationModel = preferredSummarizationModel
    }

    var hostURL: URL? {
        URL(string: host)
    }
}

extension Service {

    public func anthropic() -> AnthropicService {
        AnthropicService(host: hostURL, apiKey: token)
    }

    public func elevenLabs() -> ElevenLabsService {
        ElevenLabsService(apiKey: token)
    }

    public func fal() -> FalService {
        FalService(configuration: .init(host: hostURL, token: token))
    }

    public func groq() -> OpenAIService {
        OpenAIService(host: hostURL, apiKey: token)
    }

    public func mistral() -> MistralService {
        MistralService(host: hostURL, apiKey: token)
    }

    public func ollama() -> OllamaService {
        OllamaService(host: hostURL)
    }

    public func openAI() -> OpenAIService {
        OpenAIService(host: hostURL, apiKey: token)
    }

    public func perplexity() -> PerplexityService {
        PerplexityService(configuration: .init(host: hostURL, token: token))
    }

    public func modelService() -> ModelService {
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            anthropic()
        case .elevenLabs:
            elevenLabs()
        case .fal:
            fal()
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
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            return anthropic()
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
        switch ServiceID(rawValue: id)! {
        case .fal:
            return fal()
        case .openAI:
            return openAI()
        case .anthropic, .elevenLabs, .groq, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func embeddingService() throws -> EmbeddingService {
        guard preferredEmbeddingModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .groq:
            return groq()
        case .mistral:
            return mistral()
        case .ollama:
            return ollama()
        case .openAI:
            return openAI()
        case .anthropic, .elevenLabs, .fal, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func transcriptionService() throws -> TranscriptionService {
        guard preferredTranscriptionModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .groq:
            return groq()
        case .openAI:
            return openAI()
        case .anthropic, .elevenLabs, .fal, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func speechService() throws -> SpeechService {
        guard preferredSpeechModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .elevenLabs:
            return elevenLabs()
        case .groq:
            return groq()
        case .openAI:
            return openAI()
        case .anthropic, .fal, .mistral, .ollama, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func summarizationService() throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            return anthropic()
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
        self.preferredSpeechModel = service.preferredSpeechModel
        self.preferredSummarizationModel = service.preferredSummarizationModel
    }
}
