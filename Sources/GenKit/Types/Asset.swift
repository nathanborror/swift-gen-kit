import Foundation

public struct Asset: Codable {
    let name: String
    let data: Data?
    let kind: Kind
    let location: Location
    
    public enum Location: Codable {
        case document
        case bundle
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
