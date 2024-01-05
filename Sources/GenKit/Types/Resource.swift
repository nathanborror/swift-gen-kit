import Foundation

public enum Resource: Codable, Equatable, Hashable {
    case document(String) // Located in the documents directory
    case bundle(String) // Embedded in the bundle
    case data(Data) // Raw data
}
