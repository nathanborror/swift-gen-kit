import Foundation
import Perplexity

extension PerplexityService {
    
    func encode(messages: [Message]) -> [Perplexity.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Perplexity.Message {
        .init(
            role: encode(role: message.role),
            content: encode(contents: message.contents) ?? ""
        )
    }

    func encode(contents: [Message.Content]?) -> String? {
        contents?.compactMap {
            switch $0 {
            case .text(let text):
                return text
            case .json(let json):
                return json.object
            default:
                return nil
            }
        }.joined()
    }

    func encode(tools: [Tool]) -> [Perplexity.Message] {
        tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Perplexity.Message {
        let jsonData = try? JSONEncoder().encode(tool.function.parameters)
        let json = String(data: jsonData!, encoding: .utf8)!
        
        return .init(
            role: .user,
            content: """
                Consider the following JSON Schema based on the 2020-12 specification:
                
                ```json
                \(json)
                ```
                
                This JSON Schema represents the format I want you to follow to generate your answer. You will only \
                respond with a JSON object. Do not provide explanations. Generate a JSON object that will contain \
                the following information:
                
                \(tool.function.description)
                """
        )
    }
    
    func encode(role: Message.Role) -> Perplexity.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
}
