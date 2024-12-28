import Foundation

public final class ContentParser {
    public static let shared = ContentParser()

    public struct Result: Sendable {
        public var contents: [Content]

        public enum Content: Sendable {
            case text(String)
            case tag(Tag)
        }

        public struct Tag: Sendable {
            public let name: String
            public let content: String?
            public let params: [String: String]

            public init(name: String, content: String? = nil, params: [String : String] = [:]) {
                self.name = name
                self.content = content
                self.params = params
            }
        }

        public init(contents: [Content]) {
            self.contents = contents
        }

        public func first(tag name: String) -> Tag? {
            for content in contents {
                if case .tag(let tag) = content {
                    if tag.name == name { return tag }
                }
            }
            return nil
        }
    }

    private let tagPattern = #/<(?<name>[^>\s]+)(?<params>\s+[^>]+)?>(?<content>.*?)(?:<\/\k<name>>|$)/#
    private let tagParamsPattern = #/(?<name>\w+)="(?<value>[^"]*)"/#

    private init() {}

    public func parse(input: String, tags: [String] = []) throws -> Result {
        let matches = input.ranges(of: tagPattern.dotMatchesNewlines())
        var contents: [Result.Content] = []
        var positionIndex = input.startIndex

        // Append text to contents by checking if the last item in the contents array is already a
        // text element. When it is, the text gets appended rather than creating a new text element.
        let appendToContent: (String) -> Void = { text in
            if case .text(let lastText) = contents.last {
                contents[contents.count - 1] = .text(lastText + text)
            } else {
                contents.append(.text(text))
            }
        }

        for range in matches {

            // Add text before the tag if there's any
            if positionIndex < range.lowerBound {
                let textRange = positionIndex..<range.lowerBound
                let text = String(input[textRange])
                contents.append(.text(text))
            }

            // Extract tag information
            let match = input[range]
            if let output = try? tagPattern.dotMatchesNewlines().wholeMatch(in: match)?.output {
                let name = String(output.name)
                let content = String(output.content)
                let params = try parseTagParams(output.params)

                if tags.isEmpty || tags.contains(name) {
                    contents.append(.tag(.init(name: name, content: content, params: params)))
                } else {
                    let text = String(match)
                    appendToContent(text)
                }
            }

            // Update position index
            positionIndex = range.upperBound
        }

        // Add any remaining text after the last tag
        if positionIndex < input.endIndex {
            let text = String(input[positionIndex...])
            appendToContent(text)
        }

        // Filter out any text content with empty strings after stripping whitespace
        contents = contents.filter { content in
            switch content {
            case .text(let text):
                return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .tag(let tag):
                return true
            }
        }
        return .init(contents: contents)
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
