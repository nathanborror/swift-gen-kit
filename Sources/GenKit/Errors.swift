import Foundation

enum ServiceError: Error {
    case missingService
    case missingServiceHost
    case missingServiceToken
    case missingServiceHostAndToken
    case missingImageData
    case missingUserMessage
    case unsupportedResponseFormat
    case unsupportedService
    case notImplemented
}
