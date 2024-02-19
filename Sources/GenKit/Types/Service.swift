// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Codable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var host: URL?
    public var token: String?
    public var models: [Model]
    
    public var preferredChatModel: String?
    public var preferredImageModel: String?
    public var preferredEmbeddingModel: String?
    public var preferredTranscriptionModel: String?
    public var preferredToolModel: String?
    public var preferredVisionModel: String?
    public var preferredSpeechModel: String?
    
    public var requiresHost: Bool?
    public var requiresToken: Bool?
    
    public init(id: String, name: String, host: URL? = nil, token: String? = nil, models: [Model] = [],
                preferredChatModel: String? = nil, preferredImageModel: String? = nil, 
                preferredEmbeddingModel: String? = nil, preferredTranscriptionModel: String? = nil,
                preferredToolModel: String? = nil, preferredVisionModel: String? = nil,
                preferredSpeechModel: String? = nil, requiresHost: Bool? = nil, requiresToken: Bool? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.token = token
        self.models = models
        
        self.preferredChatModel = preferredChatModel
        self.preferredImageModel = preferredImageModel
        self.preferredEmbeddingModel = preferredEmbeddingModel
        self.preferredTranscriptionModel = preferredTranscriptionModel
        self.preferredToolModel = preferredToolModel
        self.preferredVisionModel = preferredVisionModel
        self.preferredSpeechModel = preferredSpeechModel
        
        self.requiresHost = requiresHost
        self.requiresToken = requiresToken
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
    
    public var missingHost: Bool {
        guard let req = requiresHost, req else { return false }
        return host == nil
    }
    
    public var missingToken: Bool {
        guard let req = requiresToken, req else { return false }
        return token == nil
    }
}
