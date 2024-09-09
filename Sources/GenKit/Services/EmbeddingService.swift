import Foundation

public protocol EmbeddingService: Sendable {
    func embeddings(model: Model, input: String) async throws -> [Double]
}
