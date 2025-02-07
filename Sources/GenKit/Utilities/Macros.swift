import Foundation

@attached(peer, names: prefixed(Tool_))
public macro Tool() = #externalMacro(module: "GenMacro", type: "ToolMacro")

public protocol Toolable {
    associatedtype Input: Codable
    associatedtype Output: Codable

    static var schema: [String: Value] { get }

    static func call(_ input: Input) async throws -> Output
}
