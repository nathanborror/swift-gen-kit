import Foundation
import SharedKit

public struct Run: Codable, Identifiable, Sendable {
    public var id: String
    public var messages: [Message]
    public var started: Date
    public var ended: Date?
    
    public init(id: String = .id, messages: [Message] = [], started: Date = .now, ended: Date? = nil) {
        self.id = id
        self.messages = messages
        self.started = started
        self.ended = ended
    }
}
