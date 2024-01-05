import Foundation

public protocol ImageService {
    func imagine(request: ImagineServiceRequest) async throws -> [Data]
}

public struct ImagineServiceRequest {
    public var model: String
    public var prompt: String
    public var n: Int
    public var size: String
    
    public init(model: String, prompt: String, n: Int = 1, size: String) {
        self.model = model
        self.prompt = prompt
        self.n = n
        self.size = size
    }
}
