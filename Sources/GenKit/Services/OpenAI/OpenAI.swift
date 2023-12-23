import Foundation
import OSLog
import OpenAI

private let logger = Logger(subsystem: "OpenAIService", category: "GenKit")

public final class OpenAIService: ChatService {
    
    public static var shared: OpenAIService = {
        guard let token = Bundle.main.infoDictionary?["OpenAIToken"] as? String else {
            fatalError("OpenAI token missing")
        }
        return OpenAIService(token: token)
    }()
    
    private var client: OpenAIProtocol
    
    init(token: String) {
        self.client = OpenAI(apiToken: token)
    }
    
    public func completion(request: ChatServiceRequest) async throws -> Message {
        let query = ChatQuery(
            model: request.model,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice)
        )
        let result = try await client.chats(query: query)
        return decode(result: result)
    }
    
    public func completionStream(request: ChatServiceRequest, delta: (Message) async -> Void) async throws {
        let query = ChatQuery(
            model: request.model,
            messages: encode(messages: request.messages),
            tools: encode(tools: request.tools),
            toolChoice: encode(toolChoice: request.toolChoice)
        )
        let stream: AsyncThrowingStream<ChatStreamResult, Error> = client.chatsStream(query: query)
        for try await result in stream {
            let message = decode(result: result)
            await delta(message)
        }
    }
    
    public func embeddings(model: String, input: String) async throws -> [Double] {
        let query = EmbeddingsQuery(model: model, input: input)
        let result = try await client.embeddings(query: query)
        return result.data.first?.embedding ?? []
    }
}
