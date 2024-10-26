import Foundation
import SharedKit

public struct Model: Codable, Identifiable, Sendable {
    public var id: ID<Model>
    public var family: String?
    public var name: String?
    public var owner: String
    public var contextWindow: Int?
    public var maxOutput: Int?
    public var trainingCutoff: Date?
    
    public init(id: Model.ID, family: String? = nil, name: String? = nil, owner: String, contextWindow: Int? = nil, maxOutput: Int? = nil, trainingCutoff: Date? = nil) {
        self.id = id
        self.family = family
        self.name = name
        self.owner = owner
        self.contextWindow = contextWindow
        self.maxOutput = maxOutput
        self.trainingCutoff = trainingCutoff
    }
}
