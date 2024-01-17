// A convenient structure used to manage service credentials, available models and preferred models to use within
// an application or implementation.

import Foundation

public struct Service: Codable {
    public var id: String
    public var name: String
    public var host: URL?
    public var token: String?
    public var models: [Model]
    
    public var preferredChatModel: String?
    public var preferredImageModel: String?
    public var preferredEmbeddingModel: String?
    public var preferredTranscriptionModel: String?
    
    init(id: String, name: String, host: URL? = nil, token: String? = nil, models: [Model] = [],
         preferredChatModel: String? = nil, preferredImageModel: String? = nil, preferredEmbeddingModel: String? = nil,
         preferredTranscriptionModel: String? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.token = token
        self.models = models
        self.preferredChatModel = preferredChatModel
        self.preferredImageModel = preferredImageModel
        self.preferredEmbeddingModel = preferredEmbeddingModel
        self.preferredTranscriptionModel = preferredTranscriptionModel
    }
}
