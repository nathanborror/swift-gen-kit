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
            images: encode(attachments: message.attachments)
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
    
    func encode(attachments: [Message.Attachment]) -> [Data]? {
        // Filter attachments to only images and igonore noops
        let assets: [Asset] = attachments
            .map { (attachment) -> Asset? in
                guard case .asset(let asset) = attachment else { return nil }
                return asset
            }
            .filter { $0?.kind == .image }
            .filter { $0?.noop == false }
            .compactMap { $0 }
        
        // Prepare all the image assets attached to the message
        let dataList = assets.map { (asset) -> Data? in
            return asset.data
        }.compactMap { $0 }
        
        return dataList.count > 0 ? dataList : nil
    }
}
