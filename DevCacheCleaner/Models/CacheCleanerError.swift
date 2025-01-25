import Foundation

enum CacheCleanerError: LocalizedError {
    case applicationNotInstalled(String)
    case applicationNotRunning(String)
    case cleaningFailed(String, Error?)
    case directoryNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .applicationNotInstalled(let appName):
            return "\(appName) is not installed"
        case .applicationNotRunning(let appName):
            return "\(appName) is not running"
        case .cleaningFailed(let name, let error):
            if let error = error {
                return "Failed to clean \(name): \(error.localizedDescription)"
            }
            return "Failed to clean \(name)"
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        }
    }
} 