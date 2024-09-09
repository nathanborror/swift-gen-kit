import Foundation

public struct Model: Codable, Identifiable, Sendable {
    public var id: String
    public var owner: String
    public var contextWindow: Int?
    public var maxOutput: Int?
    public var trainingCutoff: Date?
    
    public init(id: String, owner: String, contextWindow: Int? = nil, maxOutput: Int? = nil, trainingCutoff: Date? = nil) {
        self.id = id
        self.owner = owner
        self.contextWindow = contextWindow
        self.maxOutput = maxOutput
        self.trainingCutoff = trainingCutoff
    }
}
