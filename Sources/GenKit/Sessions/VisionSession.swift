import Foundation

public class VisionSession {
    public static let shared = VisionSession()
    
    public func stream(_ request: VisionSessionRequest) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let runID = String.id
                
                var messages = request.messages
                
                let req = VisionServiceRequest(
                    model: request.model,
                    messages: messages
                )
                try await request.service.completionStream(request: req) { update in
                    var message = update
                    message.runID = runID
                    
                    messages = apply(message: message, messages: messages)
                    continuation.yield(update)
                }
                continuation.finish()
            }
        }
    }
    
    public func completion(_ request: VisionSessionRequest) async throws -> VisionSessionResponse {
        let runID = String.id
        
        var messages = request.messages
        var response = VisionSessionResponse(messages: [])
        
        let req = VisionServiceRequest(
            model: request.model,
            messages: messages
        )
        var message = try await request.service.completion(request: req)
        message.runID = runID
        
        response.messages = apply(message: message, messages: response.messages)
        messages = apply(message: message, messages: messages)
        
        return response
    }
    
    func apply(message: Message, messages: [Message]) -> [Message] {
        var messages = messages
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            return messages
        } else {
            messages.append(message)
            return messages
        }
    }
}

// MARK: - Types

public struct VisionSessionRequest {
    public typealias ToolCallback = @Sendable (ToolCall) async throws -> ToolCallResponse
    
    public let service: VisionService
    public let model: String
    public let toolCallback: ToolCallback?
    
    public private(set) var messages: [Message] = []
    public private(set) var memories: [String] = []
    
    public init(service: VisionService, model: String, toolCallback: ToolCallback? = nil) {
        self.service = service
        self.model = model
        self.toolCallback = toolCallback
    }
    
    public mutating func with(messages: [Message]) {
        self.messages = messages
    }
    
    public mutating func with(memories: [String]) {
        self.memories = memories
    }
}

public struct VisionSessionResponse {
    public var messages: [Message]
}

enum VisionSessionError: Error {
    case missingMessage
    case unknown
}
