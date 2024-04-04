import Foundation

enum ServiceError: Error {
    case missingService
    case missingCredentials
    case missingImageData
    case missingUserMessage
    case unsupportedResponseFormat
    case unsupportedService
    case notImplemented
}
