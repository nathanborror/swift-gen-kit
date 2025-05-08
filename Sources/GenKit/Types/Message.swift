import Foundation
import SharedKit

public struct Message: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var role: Role
    public var contents: [Content]?
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: [String: Value]
    public var created: Date
    public var modified: Date

    public enum Role: String, CaseIterable, Codable, Hashable, Sendable {
        case system, assistant, user, tool
    }

    public enum Content: Codable, Hashable, Sendable {
        case text(String)
        case image(Image)
        case audio(Audio)
        case json(JSON)
        case file(File)

        public struct Image: Codable, Hashable, Sendable {
            public var url: URL
            public var format: Format
            public var detail: String?

            public enum Format: String, CaseIterable, Codable, Hashable, Sendable {
                case jpeg = "image/jpeg"
                case png  = "image/png"
                case gif  = "image/gif"
                case webp = "image/webp"
                case pdf  = "application/pdf"
            }

            public init(url: URL, format: Format, detail: String? = nil) {
                self.url = url
                self.format = format
                self.detail = detail
            }
        }

        public struct Audio: Codable, Hashable, Sendable {
            public var url: URL
            public var format: Format

            public enum Format: String, CaseIterable, Codable, Hashable, Sendable {
                case mp3 = "mp3"
                case wav = "wav"
            }

            public init(url: URL, format: Format) {
                self.url = url
                self.format = format
            }
        }

        public struct JSON: Codable, Hashable, Sendable {
            public let kind: String
            public let object: String

            public init(kind: String, object: String) {
                self.kind = kind
                self.object = object
            }
        }

        public struct File: Codable, Hashable, Sendable {
            public var url: URL
            public var type: String
        }
    }

    public enum FinishReason: String, CaseIterable, Codable, Hashable, Sendable {
        case stop, length, toolCalls, contentFilter, cancelled, error
    }

    public enum Attachment: Codable, Hashable, Sendable {
        case agent(String)
        case file(String, String)
    }

    public var referenceID: String? {
        set { metadata["referenceID"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["referenceID"]?.stringValue ?? "" }
    }

    public var runID: String? {
        set { metadata["runID"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["runID"]?.stringValue ?? "" }
    }

    public var modelID: String? {
        set { metadata["modelID"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["modelID"]?.stringValue ?? "" }
    }

    public init(id: String = .id, referenceID: String? = nil, runID: String? = nil, modelID: String? = nil,
                role: Role, contents: [Content], attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil,
                toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil,
                metadata: [String: Value] = [:]) {
        self.id = id
        self.role = role
        self.contents = contents
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
        self.finishReason = finishReason
        self.metadata = metadata
        self.created = .now
        self.modified = .now

        // Metadata
        self.referenceID = referenceID
        self.runID = runID
        self.modelID = modelID
    }

    public init(id: String = .id, referenceID: String? = nil, runID: String? = nil, modelID: String? = nil,
                role: Role, content: String? = nil, attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil,
                toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil,
                metadata: [String: Value] = [:]) {
        self.id = id
        self.role = role
        self.contents = (content != nil) ? [.text(content!)] : nil
        self.attachments = attachments
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
        self.finishReason = finishReason
        self.metadata = metadata
        self.created = .now
        self.modified = .now

        // Metadata
        self.referenceID = referenceID
        self.runID = runID
        self.modelID = modelID
    }
}

extension Message {

    public var content: String? {
        contents?.compactMap { content in
            if case .text(let text) = content {
                return text
            }
            return nil
        }.joined(separator: "\n")
    }
}
