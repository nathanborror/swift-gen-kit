import Foundation
import SharedKit

public struct Run: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var status: Status
    public var started: Date
    public var ended: Date?
    
    public enum Status: Codable, Sendable {
        case paused
        case generating
        case cancelled
        case failed
        case finished
    }
    
    public init(id: String = .id, status: Status = .paused, started: Date = .now, ended: Date? = nil) {
        self.id = id
        self.status = status
        self.started = started
        self.ended = ended
    }
}
