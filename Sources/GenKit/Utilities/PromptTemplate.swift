import Foundation

public func PromptTemplate(_ template: String, with context: [String: String] = [:]) -> String {
    template.replacing(#/{{(?<key>\w+)}}/#) { match in
        let key = String(match.output.key)
        return context[key] ?? ""
    }
}
