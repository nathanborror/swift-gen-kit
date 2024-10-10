import Foundation

public protocol EmbeddingService: Sendable {
    func embeddings(_ request: EmbeddingServiceRequest) async throws -> [Double]
}

public struct EmbeddingServiceRequest {
    public var model: Model
    public var input: String
}
