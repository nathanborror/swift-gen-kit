import Foundation
import SharedKit

public struct Message: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var referenceID: String?
    public var runID: String?
    public var modelID: String?
    public var role: Role
    public var contents: [Content]?
    public var attachments: [Attachment]
    public var toolCalls: [ToolCall]?
    public var toolCallID: String?
    public var name: String?
    public var finishReason: FinishReason?
    public var metadata: Metadata?
    public var created: Date
    public var modified: Date

    public enum Role: String, CaseIterable, Codable, Hashable, Sendable {
        case system, assistant, user, tool
    }

    public enum Content: Codable, Hashable, Sendable {
        case text(String)
        case image(data: Data, format: ImageFormat)
        case audio(data: Data, format: AudioFormat)

        public enum ImageFormat: String, CaseIterable, Codable, Hashable, Sendable {
            case jpeg = "image/jpeg"
            case png  = "image/png"
            case gif  = "image/gif"
            case webp = "image/webp"
            case pdf  = "application/pdf"
        }

        public enum AudioFormat: String, CaseIterable, Codable, Hashable, Sendable {
            case mp3 = "mp3"
            case wav = "wav"
        }
    }

    public enum FinishReason: String, CaseIterable, Codable, Hashable, Sendable {
        case stop, length, toolCalls, contentFilter, cancelled, error
    }

    public enum Attachment: Codable, Hashable, Sendable {
        case agent(String)
        case file(String, String)
    }

    public init(id: String = .id, referenceID: String? = nil, runID: String? = nil, modelID: String? = nil,
                role: Role, contents: [Content], attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil,
                toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil, metadata: Metadata? = nil) {
        self.id = id
        self.referenceID = referenceID
        self.runID = runID
        self.modelID = modelID
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
    }

    public init(id: String = .id, referenceID: String? = nil, runID: String? = nil, modelID: String? = nil,
                role: Role, content: String? = nil, attachments: [Attachment] = [], toolCalls: [ToolCall]? = nil,
                toolCallID: String? = nil, name: String? = nil, finishReason: FinishReason? = nil, metadata: Metadata? = nil) {
        self.id = id
        self.referenceID = referenceID
        self.runID = runID
        self.modelID = modelID
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
