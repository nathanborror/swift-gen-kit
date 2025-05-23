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
        case deepseek
        case elevenLabs
        case fal
        case grok
        case groq
        case llama
        case mistral
        case ollama
        case openAI
        case openRouter
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

    public func anthropic(session: URLSession?) -> AnthropicService {
        AnthropicService(session: session, host: hostURL, apiKey: token)
    }

    public func deepseek(session: URLSession?) -> OpenAIService {
        OpenAIService(session: session, host: hostURL, apiKey: token)
    }

    public func elevenLabs(session: URLSession?) -> ElevenLabsService {
        ElevenLabsService(session: session, apiKey: token)
    }

    public func fal(session: URLSession?) -> FalService {
        FalService(session: session, host: hostURL, apiKey: token)
    }

    public func grok(session: URLSession?) -> OpenAIService {
        OpenAIService(session: session, host: hostURL, apiKey: token)
    }

    public func groq(session: URLSession?) -> OpenAIService {
        OpenAIService(session: session, host: hostURL, apiKey: token)
    }

    public func llama(session: URLSession?) -> LlamaService {
        LlamaService(session: session, host: hostURL, apiKey: token)
    }

    public func mistral(session: URLSession?) -> MistralService {
        MistralService(session: session, host: hostURL, apiKey: token)
    }

    public func ollama(session: URLSession?) -> OllamaService {
        OllamaService(session: session, host: hostURL)
    }

    public func openAI(session: URLSession?) -> OpenAIService {
        OpenAIService(session: session, host: hostURL, apiKey: token)
    }

    public func openRouter(session: URLSession?) -> OpenAIService {
        OpenAIService(session: session, host: hostURL, apiKey: token)
    }

    public func perplexity(session: URLSession?) -> PerplexityService {
        PerplexityService(session: session, host: hostURL, apiKey: token)
    }

    public func modelService(session: URLSession?) -> ModelService {
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            anthropic(session: session)
        case .deepseek:
            deepseek(session: session)
        case .elevenLabs:
            elevenLabs(session: session)
        case .fal:
            fal(session: session)
        case .grok:
            grok(session: session)
        case .groq:
            groq(session: session)
        case .llama:
            llama(session: session)
        case .mistral:
            mistral(session: session)
        case .ollama:
            ollama(session: session)
        case .openAI:
            openAI(session: session)
        case .openRouter:
            openRouter(session: session)
        case .perplexity:
            perplexity(session: session)
        }
    }

    public func chatService(session: URLSession?) throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            return anthropic(session: session)
        case .deepseek:
            return deepseek(session: session)
        case .grok:
            return grok(session: session)
        case .groq:
            return groq(session: session)
        case .llama:
            return llama(session: session)
        case .mistral:
            return mistral(session: session)
        case .ollama:
            return ollama(session: session)
        case .openAI:
            return openAI(session: session)
        case .openRouter:
            return openRouter(session: session)
        case .perplexity:
            return perplexity(session: session)
        case .elevenLabs, .fal:
            throw ServiceError.unsupportedService
        }
    }

    public func imageService(session: URLSession?) throws -> ImageService {
        guard preferredImageModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .fal:
            return fal(session: session)
        case .openAI:
            return openAI(session: session)
        case .anthropic, .deepseek, .elevenLabs, .grok, .groq, .llama, .mistral, .ollama, .openRouter, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func embeddingService(session: URLSession?) throws -> EmbeddingService {
        guard preferredEmbeddingModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .groq:
            return groq(session: session)
        case .grok:
            return grok(session: session)
        case .mistral:
            return mistral(session: session)
        case .ollama:
            return ollama(session: session)
        case .openAI:
            return openAI(session: session)
        case .anthropic, .deepseek, .elevenLabs, .fal, .llama, .openRouter, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func transcriptionService(session: URLSession?) throws -> TranscriptionService {
        guard preferredTranscriptionModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .groq:
            return groq(session: session)
        case .openAI:
            return openAI(session: session)
        case .anthropic, .deepseek, .elevenLabs, .fal, .grok, .llama, .mistral, .ollama, .openRouter, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func speechService(session: URLSession?) throws -> SpeechService {
        guard preferredSpeechModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .elevenLabs:
            return elevenLabs(session: session)
        case .fal:
            return fal(session: session)
        case .groq:
            return groq(session: session)
        case .openAI:
            return openAI(session: session)
        case .anthropic, .deepseek, .grok, .llama, .mistral, .ollama, .openRouter, .perplexity:
            throw ServiceError.unsupportedService
        }
    }

    public func summarizationService(session: URLSession?) throws -> ChatService {
        guard preferredChatModel != nil else {
            throw ServiceError.missingService
        }
        switch ServiceID(rawValue: id)! {
        case .anthropic:
            return anthropic(session: session)
        case .deepseek:
            return deepseek(session: session)
        case .grok:
            return grok(session: session)
        case .groq:
            return groq(session: session)
        case .llama:
            return llama(session: session)
        case .mistral:
            return mistral(session: session)
        case .ollama:
            return ollama(session: session)
        case .openAI:
            return openAI(session: session)
        case .openRouter:
            return openRouter(session: session)
        case .perplexity:
            return perplexity(session: session)
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
