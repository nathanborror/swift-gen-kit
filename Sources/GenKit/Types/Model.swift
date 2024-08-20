import Foundation

public struct Model: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var owner: String
    
    public init(id: String, owner: String) {
        self.id = id
        self.owner = owner
    }
}
