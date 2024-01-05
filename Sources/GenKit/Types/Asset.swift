import Foundation

public struct Asset: Codable, Equatable, Hashable {
    public let name: String
    public let data: Data?
    public let kind: Kind
    public let location: Location
    
    public enum Location: Codable {
        case filesystem
        case bundle
        case cache
        case url
        case none
    }
    
    public enum Kind: Codable {
        case image
        case video
        case audio
    }
    
    public init(name: String, data: Data? = nil, kind: Kind, location: Location) {
        self.name = name
        self.data = data
        self.kind = kind
        self.location = location
    }
}
