import Foundation

public protocol ModelService {
    func models() async throws -> [Model]
}
