import Foundation

public protocol ModelService: Sendable {
    func models() async throws -> [Model]
}
