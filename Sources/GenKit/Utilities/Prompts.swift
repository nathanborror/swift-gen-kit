import Foundation
import SharedKit
import JSONSchema
import Yams

public func PromptTemplate(_ template: String, with context: [String: Value] = [:]) -> String {
    template.replacing(#/{{(?<key>\w+)}}/#) { match in
        let key = String(match.output.key)
        return "\(context[key] ?? "")"
    }
}

public struct Prompt: Codable {
    public var model: String
    public var input: Input?
    public var output: JSONSchema?
    public var instructions: String?

    public struct Input: Codable {
        public var schema: [String: String]
    }

    public init(model: String, input: Input? = nil, output: JSONSchema? = nil, instructions: String? = nil) {
        self.model = model
        self.input = input
        self.output = output
        self.instructions = instructions
    }

    public init(_ input: String) throws {
        let pattern = #/(?s)\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<instructions>.*)\z/#

        guard let match = input.firstMatch(of: pattern) else {
            throw PromptError.badFormatting
        }
        let yaml = String(match.output.yaml)
        let instructions = String(match.output.instructions)

        var prompt = try YAMLDecoder().decode(Prompt.self, from: yaml.data(using: .utf8)!)
        prompt.instructions = instructions
        self = prompt
    }
}

public enum PromptError: Error {
    case badFormatting
}
