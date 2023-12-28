import Foundation

public protocol EmbeddingService {
    func embeddings(model: String, input: String) async throws -> [Double]
}
