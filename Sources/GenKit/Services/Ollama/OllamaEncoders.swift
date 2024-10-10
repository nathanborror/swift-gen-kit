import Foundation
import Ollama

extension OllamaService {
    
    func encode(messages: [Message]) -> [Ollama.Message] {
        if messages.count == 1 { // When there's just one message it has to be from the user.
            var message = messages[0]
            message.role = .user // force this to be a user message
            return [encode(message: message)]
        }
        return messages.map { encode(message: $0) }
    }
    
    func encode(message: Message) -> Ollama.Message {
        .init(
            role: encode(role: message.role),
            content: message.content ?? "",
            images: encode(attachments: message)
        )
    }
    
    func encode(tools: [Tool]) -> [Ollama.Tool] {
        tools.map { encode(tool: $0) }
    }
    
    func encode(tool: Tool) -> Ollama.Tool {
        let jsonData = try? JSONEncoder().encode(tool.function.parameters)
        let json = String(data: jsonData!, encoding: .utf8)!
        
        return .init(
            type: "function",
            function: .init(
                name: tool.function.name,
                description: tool.function.description,
                parameters: tool.function.parameters
            )
        )
    }
    
    func encode(role: Message.Role) -> Ollama.Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        case .tool: .tool
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
