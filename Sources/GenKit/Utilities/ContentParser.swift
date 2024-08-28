import Foundation

public final class ContentParser {
    public static let shared = ContentParser()
    
    private let tagPattern = #/<(?<name>[^>\s]+)(?<params>\s+[^>]+)?>(?<content>.*?)(?:<\/\k<name>>|$)/#
    private let tagParamsPattern = #/(?<name>\w+)="(?<value>[^"]*)"/#
    
    private init() {}
    
    public func parse(input: String, tags: [String] = []) throws -> ContentParserResult {
        if tags.isEmpty {
            return try parseAll(input: input)
        }
        
        var parsedTags: [ContentParserResult.Tag] = []
        
        let output = try input.replacing(tagPattern.dotMatchesNewlines()) { match in
            guard tags.contains(String(match.output.name)) else {
                return match.output.0
            }
            
            let name = String(match.output.name)
            let content = String(match.output.content)
            
            parsedTags.append(
                .init(
                    name: name,
                    content: content,
                    params: try parseTagParams(match.output.params)
                )
            )
            return "<\(name) />"
        }
        return .init(tags: parsedTags, text: output)
    }
    
    public func parseAll(input: String) throws -> ContentParserResult {
        var parsedTags: [ContentParserResult.Tag] = []
        let output = try input.replacing(tagPattern.dotMatchesNewlines()) { match in
            let name = String(match.output.name)
            let content = String(match.output.content)
            
            parsedTags.append(
                .init(
                    name: name,
                    content: content,
                    params: try parseTagParams(match.output.params)
                )
            )
            return "<\(name) />"
        }
        return .init(tags: parsedTags, text: output)
    }

    private func parseTagParams(_ input: Substring?) throws -> [String: String] {
        guard let input else { return [:] }
        let matches = input.matches(of: tagParamsPattern)
        var out: [String: String] = [:]
        for match in matches {
            let (_, name, value) = match.output
            out[String(name)] = String(value)
        }
        return out
    }
}

public struct ContentParserResult: Codable, Sendable {
    public var tags: [Tag] = []
    public var text: String = ""
    
    public struct Tag: Codable, Sendable {
        public var name: String
        public var content: String? = nil
        public var params: [String: String] = [:]
    }
    
    public func get(tag name: String) -> Tag? {
        tags.first(where: { $0.name == name})
    }
}
