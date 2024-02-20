import Foundation
import GoogleGen

extension GoogleService {
    
    func decode(result: GenerateContentResponse) -> Message {
        .init(
            role: decode(role: result.candidates),
            content: decode(content: result.candidates)
        )
    }
    
    func decode(role candidates: [Candidate]) -> Message.Role {
        guard let candiate = candidates.first else { return .assistant }
        guard let role = candiate.content.role else { return .assistant }
        return .init(rawValue: role) ?? .assistant
    }
    
    func decode(content candidates: [Candidate]) -> String? {
        candidates.map { candidate in
            candidate.content.parts.map { $0.text }.joined()
        }.joined()
    }
}
