import Foundation

public protocol ImageService: Sendable {
    func imagine(request: ImagineServiceRequest) async throws -> [Data]
}

public struct ImagineServiceRequest {
    public var model: String
    public var prompt: String
    public var n: Int?
    public var quality: String?
    public var responseFormat: String?
    public var size: String?
    public var style: String?
    public var user: String?
        
    public init(model: String, prompt: String, n: Int? = nil, quality: String? = nil, responseFormat: String? = nil, 
                size: String? = nil, style: String? = nil, user: String? = nil) {
        self.model = model
        self.prompt = prompt
        self.n = n
        self.quality = quality
        self.responseFormat = responseFormat
        self.size = size
        self.style = style
        self.user = user
    }
}
