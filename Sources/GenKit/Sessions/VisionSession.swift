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
    public let model: Model
    public let toolCallback: ToolCallback?
    
    public private(set) var system: String? = nil
    public private(set) var history: [Message] = []
    public private(set) var context: [String] = []
    
    public init(service: VisionService, model: Model, toolCallback: ToolCallback? = nil) {
        self.service = service
        self.model = model
        self.toolCallback = toolCallback
    }
    
    public mutating func with(system: String?) {
        self.system = system
    }
    
    public mutating func with(history: [Message]) {
        self.history = history
    }
    
    public mutating func with(context: [String]) {
        self.context = context
    }
    
    var messages: [Message] {
        var messages: [Message] = []
        
        // Apply user context
        var systemContext = ""
        if !context.isEmpty {
            systemContext = """
            The following is context about the current user:
            <user_context>
            \(context.joined(separator: "\n"))
            </user_context>
            """
        }
        
        // Apply system prompt
        if let system {
            messages.append(.init(kind: .instruction, role: .system, content: [system, systemContext].joined(separator: "\n\n")))
        }
        
        // Apply history
        messages += history
        
        return messages
    }
}

public struct VisionSessionResponse: Sendable {
    public var messages: [Message]
}

enum VisionSessionError: Error {
    case missingMessage
    case unknown
}
