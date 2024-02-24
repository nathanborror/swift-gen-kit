import Foundation
import Mistral

extension MistralService {
    
    func encode(messages: [Message]) -> [Mistral.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Mistral.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? ""
        )
    }
    
    func encode(role: Message.Role) -> Mistral.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
    
    func encode(tools: [Tool]) -> [Mistral.Message] {
        tools.map { encode(tool: $0) }
    }

    func encode(tool: Tool) -> Mistral.Message {
        let jsonData = try? JSONEncoder().encode(tool.function.parameters)
        let json = String(data: jsonData!, encoding: .utf8)!
        
        return .init(
            role: .user,
            content: """
                Consider the following JSON Schema based on the 2020-12 specification:
                
                ```json
                \(json)
                ```
                
                This JSON Schema represents the format I want you to follow to generate your answer. Now, generate \
                a JSON object that will contain the following information:
                
                \(tool.function.description)
                """
        )
    }
}
