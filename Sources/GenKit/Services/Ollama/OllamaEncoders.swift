import Foundation
import Ollama

extension OllamaService {
    
    func encode(messages: [Message]) -> [Ollama.Message] {
        messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Ollama.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? "",
            images: encode(attachments: message)
        )
    }
    
    func encode(tools: [Tool]) -> [Ollama.Message] {
        tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Ollama.Message {
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
    
    func encode(role: Message.Role) -> Ollama.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .assistant
        }
    }
    
    func encode(attachments message: Message) -> [Data]? {
        let assets = message.visionImages
        
        // Prepare all the image assets attached to the message
        let dataList = assets.map { (asset) -> Data? in
            return asset.data
        }.compactMap { $0 }
        
        return dataList.count > 0 ? dataList : nil
    }
}
