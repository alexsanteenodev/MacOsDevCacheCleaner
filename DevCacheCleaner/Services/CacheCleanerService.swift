import Foundation

protocol CacheCleanerService {
    func cleanDocker() async throws
    func cleanHomebrew() async throws
    func cleanLibrary() async throws
    func cleanXcode() async throws
    func cleanNPM() async throws
    func cleanCocoaPods() async throws
    func cleanGradle() async throws
    func cleanAndroidStudio() async throws
    func cleanVSCode() async throws
    func cleanPython() async throws
    func cleanRubyGems() async throws
}

// Default implementations for availability checks
extension CacheCleanerService {
    func isDockerAvailable() -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Docker.app")
    }
    
    func isHomebrewAvailable() -> Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew") ||
        FileManager.default.fileExists(atPath: "/usr/local/Homebrew")
    }
} 