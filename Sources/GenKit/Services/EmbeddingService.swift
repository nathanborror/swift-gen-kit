import Foundation

public protocol EmbeddingService: Sendable {
    func embeddings(model: String, input: String) async throws -> [Double]
}
