import Foundation

public enum Media: Codable, Equatable, Hashable {
    case document(MediaType) // Located in the documents directory
    case bundle(MediaType) // Embedded in the bundle
    case color(ColorHexValue) // just a solid color hex value
    case data(Data)
    case symbol(SymbolSystemName, ColorHexValue)
    case none
}

public enum MediaType: Codable, Equatable, Hashable {
    case image(String)
    case video(String)
    case audio(String)
    case agent(String)
}

public typealias ColorHexValue = String
public typealias SymbolSystemName = String
