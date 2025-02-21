import Foundation
import SharedKit

public func PromptTemplate(_ template: String, with context: [String: Value] = [:]) -> String {
    template.replacing(#/{{(?<key>\w+)}}/#) { match in
        let key = String(match.output.key)
        return "\(context[key] ?? "")"
    }
}
