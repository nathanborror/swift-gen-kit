import Foundation

enum ServiceError: Error {
    case missingService
    case missingCredentials
    case missingImageData
    case unsupportedResponseFormat
    case unsupportedService
    case notImplemented
}
