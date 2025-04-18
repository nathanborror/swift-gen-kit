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
    var model: String
    var service: String?
    var input: Input?
    var output: JSONSchema?
    var instructions: String?

    public struct Input: Codable {
        public var schema: [String: String]
    }

    public init(model: String, service: String? = nil, input: Input? = nil, output: JSONSchema? = nil, instructions: String? = nil) {
        self.model = model
        self.service = service
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

        let components = prompt.model.split(separator: "/", maxSplits: 1)
        guard components.count == 2 else {
            throw PromptError.badModelFormatting
        }

        prompt.service = String(components[0])
        prompt.model = String(components[1])
        prompt.instructions = instructions
        self = prompt
    }

    public func render(_ values: [String: Value] = [:]) throws -> String {
        let instructions = instructions ?? ""
        let schema = input?.schema ?? [:]

        // Check for required keys and ingore optional keys
        for (key, _) in schema {
            if key.hasSuffix("?") { continue }
            if values.keys.contains(key) { continue }
            throw PromptError.missingInput(key)
        }

        // TODO: Default values
        // Determine what the default values should be when they are optionals.

        // Replace input variables with their values
        return instructions.replacing(#/{{(?<key>\w+)}}/#) { match in
            let key = String(match.output.key)
            return "\(values[key] ?? "")"
        }
    }

    public func service(_ services: [Service]) throws -> ChatService {
        throw PromptError.unknownService
    }

    public func model(_ models: [Model]) throws -> Model {
        throw PromptError.unknownModel
    }
}

public enum PromptError: Error {
    case badFormatting
    case badModelFormatting
    case unknownService
    case unknownModel
    case missingInput(String)
}
