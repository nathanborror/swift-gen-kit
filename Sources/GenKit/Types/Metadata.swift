import Foundation

@dynamicMemberLookup
public struct Metadata: Codable, Sendable {
    public var properties: [String: String]
    
    public subscript(dynamicMember member: String) -> String {
        get {
            properties[member, default: ""]
        }
        set {
            properties[member] = newValue
        }
    }
    
    public init(_ properties: [String: String] = [:]) {
        self.properties = properties
    }
}
