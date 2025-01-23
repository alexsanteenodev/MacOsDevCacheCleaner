import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    @Published var cacheOptions: [CacheOption]
    @Published var isLoading = false
    @Published var lastCleanedDate: Date?
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    @Published var isAllSelected = false
    
    init() {
        self.cacheOptions = []
        setupCacheOptions()
    }
    
    private func setupCacheOptions() {
        cacheOptions = [
            CacheOption(title: "Docker", 
                       description: "Clean Docker system and unused images", 
                       cleanAction: cleanDocker),
            CacheOption(title: "Homebrew", 
                       description: "Clean Homebrew cache", 
                       cleanAction: cleanHomebrew),
            CacheOption(title: "General Library Cache", 
                       description: "Clean Library cache files", 
                       cleanAction: cleanLibrary),
            CacheOption(title: "Xcode", 
                       description: "Clean Xcode derived data and archives", 
                       cleanAction: cleanXcode),
            CacheOption(title: "NPM", 
                       description: "Clean NPM cache", 
                       cleanAction: cleanNPM),
            CacheOption(title: "CocoaPods", 
                       description: "Clean CocoaPods cache", 
                       cleanAction: cleanCocoaPods),
            CacheOption(title: "Gradle", 
                       description: "Clean Gradle cache", 
                       cleanAction: cleanGradle),
            CacheOption(title: "Android Studio", 
                       description: "Clean Android Studio caches", 
                       cleanAction: cleanAndroidStudio),
            CacheOption(title: "VS Code", 
                       description: "Clean VS Code caches", 
                       cleanAction: cleanVSCode),
            CacheOption(title: "Python", 
                       description: "Clean Python pip and pyc caches", 
                       cleanAction: cleanPython),
            CacheOption(title: "Ruby Gems", 
                       description: "Clean Ruby Gems cache", 
                       cleanAction: cleanRubyGems)
        ]
    }
    
    func toggleSelectAll() {
        for index in cacheOptions.indices where cacheOptions[index].isAvailable {
            cacheOptions[index].isSelected = isAllSelected
        }
    }
    
    func checkAvailableCommands() async {
        for index in cacheOptions.indices {
            cacheOptions[index].isAvailable = true
        }
    }
    
    func cleanSelectedCaches() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            for option in cacheOptions where option.isSelected {
                if !option.isAvailable {
                    continue
                }
                
                do {
                    if let cleanAction = option.cleanAction {
                        try await cleanAction()
                    }
                } catch {
                    if let currentError = errorMessage {
                        errorMessage = currentError + "\n" + option.title + ": " + (option.error ?? error.localizedDescription)
                    } else {
                        errorMessage = option.title + ": " + (option.error ?? error.localizedDescription)
                    }
                }
            }
            
            isLoading = false
            lastCleanedDate = Date()
        }
    }
    
    func refreshTools() {
        guard !isLoading else { return }
        
        isRefreshing = true
        errorMessage = nil
        
        Task {
            await checkAvailableCommands()
            isRefreshing = false
        }
    }
    
    // MARK: - Cleaning Actions
    private func cleanDocker() async throws {
        let fileManager = FileManager.default
        
        // Check Docker.app installation
        let dockerApp = "/Applications/Docker.app"
        guard fileManager.fileExists(atPath: dockerApp) else {
            throw NSError(domain: "", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Docker.app is not installed. Please install Docker Desktop for Mac first."])
        }
        
        // Check if Docker.app is running
        let workspace = NSWorkspace.shared
        guard workspace.runningApplications.contains(where: { $0.bundleIdentifier == "com.docker.docker" }) else {
            throw NSError(domain: "", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "Docker.app is not running. Please start Docker Desktop first."])
        }
        
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let dockerDataPath = homeURL.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        let dockerGroupPath = homeURL.appendingPathComponent("Library/Group Containers/group.com.docker")
        let dockerHomePath = homeURL.appendingPathComponent(".docker")
        
        try await cleanDockerPaths(fileManager: fileManager, 
                                 dockerDataPath: dockerDataPath,
                                 dockerGroupPath: dockerGroupPath,
                                 dockerHomePath: dockerHomePath)
    }
    
    private func cleanDockerPaths(fileManager: FileManager,
                                dockerDataPath: URL,
                                dockerGroupPath: URL,
                                dockerHomePath: URL) async throws {
        // Clean Docker data cache
        let vmsPath = dockerDataPath.appendingPathComponent("vms")
        if fileManager.fileExists(atPath: vmsPath.path) {
            let cacheContents = try fileManager.contentsOfDirectory(at: vmsPath,
                                                                  includingPropertiesForKeys: nil)
            for url in cacheContents where url.lastPathComponent != "hyperkit" {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Clean Docker group container cache
        if fileManager.fileExists(atPath: dockerGroupPath.path) {
            let groupContents = try fileManager.contentsOfDirectory(at: dockerGroupPath,
                                                                  includingPropertiesForKeys: nil)
            for url in groupContents where url.lastPathComponent.contains("cache") {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Clean Docker home cache
        if fileManager.fileExists(atPath: dockerHomePath.path) {
            let homeContents = try fileManager.contentsOfDirectory(at: dockerHomePath,
                                                                 includingPropertiesForKeys: nil)
            for url in homeContents where url.lastPathComponent.contains("cache") {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanHomebrew() async throws {
        let fileManager = FileManager.default
        
        // Check both Intel and Apple Silicon paths
        let intelBrewPath = "/usr/local/Homebrew"
        let appleBrewPath = "/opt/homebrew"
        
        var brewPath = ""
        if fileManager.fileExists(atPath: appleBrewPath) {
            brewPath = appleBrewPath
        } else if fileManager.fileExists(atPath: intelBrewPath) {
            brewPath = intelBrewPath
        } else {
            throw NSError(domain: "", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Homebrew is not installed"])
        }
        
        let cachePath = (brewPath as NSString).appendingPathComponent("Library/Homebrew/Cache")
        let downloadsCachePath = (brewPath as NSString).appendingPathComponent("Library/Caches/Homebrew")
        
        try await cleanHomebrewPaths(fileManager: fileManager,
                                   cachePath: cachePath,
                                   downloadsCachePath: downloadsCachePath)
    }
    
    private func cleanHomebrewPaths(fileManager: FileManager,
                                  cachePath: String,
                                  downloadsCachePath: String) async throws {
        // Clean main cache
        if fileManager.fileExists(atPath: cachePath) {
            let contents = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: cachePath),
                                                             includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Clean downloads cache
        if fileManager.fileExists(atPath: downloadsCachePath) {
            let contents = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: downloadsCachePath),
                                                             includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanLibrary() async throws {
        let fileManager = FileManager.default
        let libraryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let contents = try fileManager.contentsOfDirectory(at: libraryURL, 
                                                         includingPropertiesForKeys: nil)
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func cleanXcode() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let derivedDataURL = homeURL.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        let archivesURL = homeURL.appendingPathComponent("Library/Developer/Xcode/Archives")
        
        // Clean DerivedData
        if fileManager.fileExists(atPath: derivedDataURL.path) {
            let derivedContents = try fileManager.contentsOfDirectory(at: derivedDataURL,
                                                                    includingPropertiesForKeys: nil)
            for url in derivedContents {
                try fileManager.removeItem(at: url)
            }
        }
        
        // Clean Archives
        if fileManager.fileExists(atPath: archivesURL.path) {
            let archiveContents = try fileManager.contentsOfDirectory(at: archivesURL,
                                                                    includingPropertiesForKeys: nil)
            for url in archiveContents {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanNPM() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let npmCacheURL = homeURL.appendingPathComponent(".npm/_cacache")
        
        if fileManager.fileExists(atPath: npmCacheURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: npmCacheURL, 
                                                            includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanCocoaPods() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let cocoaPodsURL = homeURL.appendingPathComponent("Library/Caches/CocoaPods")
        
        if fileManager.fileExists(atPath: cocoaPodsURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: cocoaPodsURL, 
                                                            includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanGradle() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let gradleCacheURL = homeURL.appendingPathComponent(".gradle/caches")
        
        if fileManager.fileExists(atPath: gradleCacheURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: gradleCacheURL, 
                                                            includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }
    }
    
    private func cleanAndroidStudio() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let paths = [
            "Library/Caches/Google/AndroidStudio*",
            "Library/Application Support/Google/AndroidStudio*/caches",
            ".android/cache"
        ]
        
        for pattern in paths {
            let enumerator = FileManager.default.enumerator(
                at: homeURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )
            
            while let url = enumerator?.nextObject() as? URL {
                if url.path.contains("AndroidStudio") && url.path.contains("cache") {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
    }
    
    private func cleanVSCode() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let paths = [
            "Library/Application Support/Code/Cache",
            "Library/Application Support/Code/CachedData",
            "Library/Application Support/Code/CachedExtensions",
            ".vscode/extensions"
        ]
        
        for path in paths {
            let cacheURL = homeURL.appendingPathComponent(path)
            if fileManager.fileExists(atPath: cacheURL.path) {
                let contents = try fileManager.contentsOfDirectory(at: cacheURL, 
                                                                includingPropertiesForKeys: nil)
                for url in contents {
                    try fileManager.removeItem(at: url)
                }
            }
        }
    }
    
    private func cleanPython() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let paths = [
            "Library/Caches/pip",
            ".cache/pip"
        ]
        
        // Clean pip cache
        for path in paths {
            let cacheURL = homeURL.appendingPathComponent(path)
            if fileManager.fileExists(atPath: cacheURL.path) {
                let contents = try fileManager.contentsOfDirectory(at: cacheURL, 
                                                                includingPropertiesForKeys: nil)
                for url in contents {
                    try fileManager.removeItem(at: url)
                }
            }
        }
        
        // Clean .pyc files recursively in home directory
        if let enumerator = FileManager.default.enumerator(
            at: homeURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) {
            while let url = enumerator.nextObject() as? URL {
                if url.pathExtension == "pyc" {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
    }
    
    private func cleanRubyGems() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let gemCacheURL = homeURL.appendingPathComponent(".gem/ruby")
        
        if fileManager.fileExists(atPath: gemCacheURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: gemCacheURL, 
                                                            includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.contains("cache") {
                    try fileManager.removeItem(at: url)
                }
            }
        }
    }
} 