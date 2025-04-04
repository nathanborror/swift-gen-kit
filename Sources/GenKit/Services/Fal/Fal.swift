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
            num_images: request.n,
            output_format: .png // TODO: Use response_format
        )
        let result = try await client.textToImage(query, model: request.model.id)

        return try await withThrowingTaskGroup(of: Data?.self) { group in
            for image in result.images {
                group.addTask {
                    guard let url = URL(string: image.url) else { return nil }
                    let (data, _) = try await URLSession.shared.data(from: url)
                    return data
                }
            }
            var downloadedImages: [Data] = []
            for try await data in group {
                if let data {
                    downloadedImages.append(data)
                }
            }
            return downloadedImages
        }
    }
}

extension FalService: ModelService {
    
    public func models() async throws -> [Model] {
        let result = try await client.models()
        return result.models.map {
            Model(id: $0.id, name: $0.name, owner: $0.owner)
        }
    }
}
