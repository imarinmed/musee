import Foundation

public enum MuseeError: Error, LocalizedError, Equatable {
    case invalidArgument(String)
    case invalidData(String)
    case invalidFormat(String)
    case notFound(String)
    case ioError(String)
    case processingFailed(String)
    case visionProcessingFailed(String)
    case searchFailed(String)
    case analysisFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidArgument(message):
            "Invalid argument: \(message)"
        case let .invalidData(message):
            "Invalid data: \(message)"
        case let .invalidFormat(message):
            "Invalid format: \(message)"
        case let .notFound(message):
            "Not found: \(message)"
        case let .ioError(message):
            "I/O error: \(message)"
        case let .processingFailed(message):
            "Processing failed: \(message)"
        case let .visionProcessingFailed(message):
            "Vision processing failed: \(message)"
        case let .searchFailed(message):
            "Search failed: \(message)"
        case let .analysisFailed(message):
            "Analysis failed: \(message)"
        }
    }
}
