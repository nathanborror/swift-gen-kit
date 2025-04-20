import Foundation
import SharedKit
import JSONSchema
import Yams

public enum PromptError: Error {
    case badFormatting
    case badModelFormatting
    case unknownService
    case unknownModel
    case missingInput(String)
}

public struct Prompt: Codable {
    var model: String
    var service: String?
    var config: Config?
    var input: Input?
    var output: Output?
    var instructions: String?

    public struct Config: Codable {
        var temperature: Double?
        var topK: Int?
        var topP: Double?
        var maxOutputTokens: Int?
    }

    public struct Input: Codable {
        public var schema: [String: String]
        public var `default`: [String: Value]?
    }

    public struct Output: Codable {
        public var schema: JSONSchema
    }

    /// Returns a Prompt.
    public init(model: String, service: String? = nil, config: Config? = nil, input: Input? = nil, output: Output? = nil, instructions: String? = nil) {
        self.model = model
        self.service = service
        self.config = config
        self.input = input
        self.output = output
        self.instructions = instructions
    }

    /// Returns a Prompt based on the given URL to a file.
    public init(url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        try self.init(content)
    }

    /// Returns a Prompt based on the given string.
    public init(_ prompt: String) throws {
        let pattern = #/(?s)\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<instructions>.*)\z/#

        guard let match = prompt.firstMatch(of: pattern) else {
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

    /// Returns a prepared string representing a prompt that can be sent to a Large Language Model.
    public func render(_ values: [String: Value] = [:]) throws -> String {
        let instructions = instructions ?? ""
        let schema = input?.schema ?? [:]
        let defaults = input?.default ?? [:]

        var values = values

        // Check for required keys and ingore optional keys
        for (key, _) in schema {

            // 1. Proceed if input value is optional or has a default value
            if key.hasSuffix("?") {
                let cleanKey = String(key.dropLast())
                if values.keys.contains(cleanKey) {
                    continue
                } else if defaults.keys.contains(cleanKey) {
                    values[cleanKey] = defaults[cleanKey]
                    continue
                }
            }

            // 2. Proceed if input value for the key exists or if there is a default value
            if values.keys.contains(key) {
                continue
            } else if defaults.keys.contains(key) {
                values[key] = defaults[key]
                continue
            }

            // 3. Throw error because a value nor a default value is missing for the expected input key
            throw PromptError.missingInput(key)
        }

        // Replace input variables with their values
        return instructions.replacing(#/{{(?<key>\w+)}}/#) { match in
            let key = String(match.output.key)
            return "\(values[key] ?? "")"
        }
    }
}
