import Foundation
import SharedKit

public struct Asset: Codable, Equatable, Hashable {
    public let name: String
    public let data: Data?
    public let kind: Kind
    public let location: Location
    public let background: String?
    
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
        case symbol
    }
    
    public init(name: String, data: Data? = nil, kind: Kind, location: Location, background: String? = nil) {
        self.name = name
        self.data = data
        self.kind = kind
        self.location = location
        self.background = background
    }
}

extension Asset {
    
    public var url: URL? {
        switch location {
        case .bundle:
            return nil
        case .filesystem:
            return Resource.document(name).url
        case .cache:
            return Resource.cache(name).url
        case .url:
            return URL(string: name)
        case .none:
            return nil
        }
    }
}
