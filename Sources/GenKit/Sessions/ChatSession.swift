import Foundation
import SharedKit

public class ChatSession {
    public static let shared = ChatSession()

    public func stream(_ request: ChatSessionRequest, runLoopLimit: Int = 10, maxConcurrentToolCalls: Int = 3) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let runID = String.id
                    var messages = request.messages
                    var runLoopCount = 0
                    var runShouldContinue = true

                    while runShouldContinue {
                        guard runLoopCount < runLoopLimit else {
                            continuation.finish(throwing: ChatSessionError.maxRunLoopLimit)
                            return
                        }

                        // Prepare service request, DO NOT include a tool choice on subsequent runs, this will
                        // cause an expensive infinite loop of tool calls.
                        let req = ChatServiceRequest(
                            model: request.model,
                            messages: messages,
                            tools: request.tools,
                            toolChoice: (runLoopCount > 0) ? nil : request.tool, // FIRST REQUEST ONLY
                            options: request.options
                        )
                        try await request.service.completionStream(req) { message in
                            let message = apply(runID: runID, message: message)
                            messages = apply(message: message, messages: messages)
                            continuation.yield(message)
                        }

                        // Determine if there were any tool calls on the last message, process them by calling their
                        // repsective functions to return tool responses, then decide whether the loop should continue.
                        guard request.toolCallback != nil else {
                            break
                        }
                        let lastMessage = messages.last!
                        guard (lastMessage.toolCalls?.count ?? 0) > 0 else {
                            break
                        }
                        let (toolMessages, shouldContinue) = try await processToolCalls(in: lastMessage, callback: request.toolCallback, maxConcurrent: maxConcurrentToolCalls)
                        for message in toolMessages {
                            let message = apply(runID: runID, message: message)
                            messages = apply(message: message, messages: messages)
                            continuation.yield(message)
                        }
                        runShouldContinue = shouldContinue
                        runLoopCount += 1
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func completion(_ request: ChatSessionRequest, runLoopLimit: Int = 10, maxConcurrentToolCalls: Int = 3) async throws -> ChatSessionResponse {
        let runID = String.id

        var messages = request.messages
        var response = ChatSessionResponse(messages: [])

        var runLoopCount = 0
        var runShouldContinue = true

        while runShouldContinue {
            guard runLoopCount < runLoopLimit else {
                throw ChatSessionError.maxRunLoopLimit
            }

            // Prepare service request, DO NOT include a tool choice on subsequent runs, this will
            // cause an expensive infinite loop of tool calls.
            let req = ChatServiceRequest(
                model: request.model,
                messages: messages,
                tools: request.tools,
                toolChoice: (runLoopCount > 0) ? nil : request.tool, // FIRST REQUEST ONLY
                options: request.options
            )
            var message = try await request.service.completion(req)
            message = apply(runID: runID, message: message)

            response.messages = apply(message: message, messages: response.messages)
            messages = apply(message: message, messages: messages)

            // Determine if there were any tool calls on the last message, process them by calling their
            // repsective functions to return tool responses, then decide whether the loop should continue.
            guard request.toolCallback != nil else {
                break
            }
            guard (message.toolCalls?.count ?? 0) > 0 else {
                break
            }
            let (toolMessages, shouldContinue) = try await processToolCalls(in: message, callback: request.toolCallback, maxConcurrent: maxConcurrentToolCalls)
            for message in toolMessages {
                let message = apply(runID: runID, message: message)
                response.messages = apply(message: message, messages: response.messages)
                messages = apply(message: message, messages: messages)
            }
            runShouldContinue = shouldContinue
            runLoopCount += 1
        }

        return response
    }

    func processToolCalls(in message: Message, callback: ChatSessionRequest.ToolCallback?, maxConcurrent: Int) async throws -> ([Message], Bool) {
        guard let callback else { return ([], false) }
        guard let toolCalls = message.toolCalls else { return ([], false) }
        let runID = message.runID

        // Parallelize tool calls.
        var responses: [ToolCallResponse] = []
        await withTaskGroup(of: ToolCallResponse.self) { group in
            for toolCall in toolCalls {
                group.addTask {
                    do {
                        return try await callback(toolCall)
                    } catch {
                        let message = Message(
                            role: .tool,
                            content: "Unknown tool.",
                            toolCallID: toolCall.id,
                            name: toolCall.function?.name ?? toolCall.custom?.name,
                            metadata: ["label": .string("Unknown tool")]
                        )
                        return .init(messages: [message], shouldContinue: false)
                    }
                }
            }
            for await response in group {
                responses.append(response)
            }
        }

        // Flatten messages from task responses and annotate each message with a Run identifier.
        let messages = responses
            .flatMap { $0.messages }
            .map {
                var message = $0
                message.runID = runID
                return message
            }

        // If any task response suggests the Run should stop, stop it.
        let shouldContinue = !responses.contains(where: { $0.shouldContinue == false })

        return (messages, shouldContinue)
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

    func apply(runID: String?, message: Message) -> Message {
        var message = message
        message.runID = runID
        return message
    }
}

// MARK: - Types

public struct ChatSessionRequest {
    public typealias ToolCallback = @Sendable (ToolCall) async throws -> ToolCallResponse

    public let service: ChatService
    public let model: Model
    public let toolCallback: ToolCallback?

    public private(set) var system: String? = nil
    public private(set) var history: [Message] = []
    public private(set) var tools: [Tool] = []
    public private(set) var tool: Tool? = nil
    public private(set) var context: [String: Value] = [:]
    public private(set) var options: [String: Value] = [:]

    public init(service: ChatService, model: Model, toolCallback: ToolCallback? = nil) {
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

    public mutating func with(tools: [Tool]) {
        self.tools = tools
    }

    public mutating func with(tool: Tool?) {
        if let tool {
            self.tool = tool
            self.tools.append(tool)
        } else {
            self.tool = nil
        }
    }

    public mutating func with(context: [String: Value]) {
        self.context = context
    }

    public mutating func with(option key: String, value: Value) {
        options[key] = value
    }

    var messages: [Message] {
        var messages: [Message] = []

        // Apply user context
        var systemContext = ""
        if let memories = context["MEMORIES"] {
            systemContext = """
            The following is context about the current user:
            <user_context>
            \(memories)
            </user_context>
            """
        }

        // Apply system prompt
        if let system {
            let prompt = [system, systemContext].joined(separator: "\n\n")
            messages.append(.init(role: .system, content: prompt))
        }

        // Apply history
        messages += history

        return messages
    }
}

public struct ChatSessionResponse: Sendable {
    public var messages: [Message]

    public func extractTool<T: Codable>(name: String, type: T.Type) throws -> T {
        guard let message = messages.last else {
            throw ChatSessionError.missingMessage
        }
        guard let toolCalls = message.toolCalls else {
            throw ChatSessionError.missingToolCalls
        }
        guard let toolCall = toolCalls.first(where: { $0.function?.name == name || $0.custom?.name == name }) else {
            throw ChatSessionError.missingToolCall
        }
        guard let data = toolCall.function?.arguments.data(using: .utf8) ?? toolCall.custom?.input.data(using: .utf8) else {
            throw ChatSessionError.unknown
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

enum ChatSessionError: Error {
    case missingMessage
    case missingToolCalls
    case missingToolCall
    case missingTool
    case maxRunLoopLimit
    case unknown
}
