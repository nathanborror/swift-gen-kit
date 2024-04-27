import Foundation
import OSLog
import Fal

private let logger = Logger(subsystem: "FalService", category: "GenKit")

public final class FalService {
    
    private var client: FalClient
    
    public init(configuration: FalClient.Configuration) {
        self.client = FalClient(configuration: configuration)
        logger.info("Fal Service: \(self.client.configuration.host.absoluteString)")
    }
}

extension FalService: ImageService {
    
    public func imagine(request: ImagineServiceRequest) async throws -> [Data] {
        let query = Fal.TextToImageRequest(
            prompt: request.prompt,
            numImages: request.n
        )
        let result = try await client.textToImage(query, model: request.model)
        return try result.images.map {
            guard let url = URL(string: $0.url) else { return nil }
            return try Data(contentsOf: url)
        }.compactMap { $0 }
    }
}

extension FalService: ModelService {
    
    public func models() async throws -> [Model] {
        [
            .init(id: "fast-sdxl", owner: "fal"),
            .init(id: "stable-cascade", owner: "fal"),
            .init(id: "lora", owner: "fal"),
            .init(id: "fast-turbo-diffusion", owner: "fal"),
        ]
    }
}
