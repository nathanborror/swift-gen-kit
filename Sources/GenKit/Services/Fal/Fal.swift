import Foundation
import OSLog
import Fal

private let logger = Logger(subsystem: "FalService", category: "GenKit")

public actor FalService {
    
    private var client: FalClient
    
    public init(configuration: FalClient.Configuration) {
        self.client = FalClient(configuration: configuration)
    }
}

extension FalService: ImageService {
    
    public func imagine(_ request: ImagineServiceRequest) async throws -> [Data] {
        let query = Fal.TextToImageRequest(
            prompt: request.prompt,
            numImages: request.n
        )
        let result = try await client.textToImage(query, model: request.model.id.rawValue)
        return try result.images.map {
            guard let url = URL(string: $0.url) else { return nil }
            return try Data(contentsOf: url)
        }.compactMap { $0 }
    }
}

extension FalService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(id: Model.ID($0.id), name: $0.name, owner: $0.owner)
        }
    }
}
