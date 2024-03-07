import Foundation
import SharedKit

public struct Asset: Codable, Equatable, Hashable {
    public let name: String
    public let data: Data?
    public let kind: Kind
    public let location: Location
    public let background: String?
    public let foreground: String?
    public let description: String?
    public let metadata: [String: String]
    
    /// Set to false when you want the asset to be included in the message history. Typically used for multimodal requests.
    public let noop: Bool
    
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
    
    public init(name: String, data: Data? = nil, kind: Kind, location: Location, background: String? = nil,
                foreground: String? = nil, description: String? = nil, metadata: [String: String] = [:],
                noop: Bool = true) {
        self.name = name
        self.data = data
        self.kind = kind
        self.location = location
        self.background = background
        self.foreground = foreground
        self.description = description
        self.metadata = metadata
        self.noop = noop
    }
}

extension Asset {
    
    public static var empty: Self {
        .init(
            name: "sparkle",
            kind: .symbol,
            location: .none,
            background: "#F5F5F5",
            foreground: "#7A7A7A"
        )
    }
    
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
