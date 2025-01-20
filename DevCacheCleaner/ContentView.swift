//
//  ContentView.swift
//  DevCacheCleaner
//
//  Created by Oleksandr Hanhaliuk on 19/01/2025.
//

import SwiftUI

#if DEBUG
struct Logger {
    static func debug(_ message: String) {
        print("🔍 Debug:", message)
    }
    
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            print("❌ Error:", message, "Details:", error)
        } else {
            print("❌ Error:", message)
        }
    }
    
    static func command(_ command: String, output: String?) {
        print("⚡️ Command:", command)
        if let output = output {
            print("📝 Output:", output)
        }
    }
}
#endif

struct CacheOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let command: String
    let commandName: String
    var fullPath: String?
    var isSelected: Bool = false
    var isAvailable: Bool = true
    var error: String?
    var cleanAction: (() async throws -> Void)?
}

struct ContentView: View {
    @State internal var cacheOptions = [
        CacheOption(title: "Docker", 
                   description: "Clean Docker system and unused images", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                       
                       // Clean Docker caches
                       do {
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
                       } catch {
                           throw NSError(domain: "", code: 3,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to clean Docker cache: \(error.localizedDescription)"])
                       }
                   }),
        CacheOption(title: "Homebrew", 
                   description: "Clean Homebrew cache", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "General Library Cache", 
                   description: "Clean Library cache files", 
                   command: "",
                   commandName: "",
                   cleanAction: {
                       let fileManager = FileManager.default
                       let libraryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                       
                       do {
                           let contents = try fileManager.contentsOfDirectory(at: libraryURL, 
                                                                           includingPropertiesForKeys: nil)
                           for url in contents {
                               try? fileManager.removeItem(at: url)
                           }
                       } catch {
                           throw error
                       }
                   }),
        CacheOption(title: "Xcode", 
                   description: "Clean Xcode derived data and archives", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "NPM", 
                   description: "Clean NPM cache", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "CocoaPods", 
                   description: "Clean CocoaPods cache", 
                   command: "",
                   commandName: "",
                   cleanAction: {
                       let fileManager = FileManager.default
                       let homeURL = fileManager.homeDirectoryForCurrentUser
                       let cocoaPodsURL = homeURL.appendingPathComponent("Library/Caches/CocoaPods")
                       
                       do {
                           if fileManager.fileExists(atPath: cocoaPodsURL.path) {
                               let contents = try fileManager.contentsOfDirectory(at: cocoaPodsURL, 
                                                                               includingPropertiesForKeys: nil)
                               for url in contents {
                                   try? fileManager.removeItem(at: url)
                               }
                           }
                       } catch {
                           throw error
                       }
                   }),
        CacheOption(title: "Gradle", 
                   description: "Clean Gradle cache", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "Android Studio", 
                   description: "Clean Android Studio caches", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "VS Code", 
                   description: "Clean VS Code caches", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "Python", 
                   description: "Clean Python pip and pyc caches", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
        CacheOption(title: "Ruby Gems", 
                   description: "Clean Ruby Gems cache", 
                   command: "",
                   commandName: "",
                   cleanAction: {
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
                   }),
    ]
    
    @State private var isLoading = false
    @State private var lastCleanedDate: Date?
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var isAllSelected = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Dev Cache Cleaner")
                    .font(.headline)
                
                Spacer()
                
                Button(action: refreshTools) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
                .help("Refresh tools status")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit Dev Cache Cleaner")
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Select All Section
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $isAllSelected) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select All")
                                    .font(.system(.body, weight: .medium))
                                Text("Toggle all available items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.checkbox)
                        .accessibilityIdentifier("SelectAllButton")
                        #if compiler(>=5.9)
                        .onChange(of: isAllSelected) { _, newValue in
                            for index in cacheOptions.indices where cacheOptions[index].isAvailable {
                                cacheOptions[index].isSelected = newValue
                            }
                        }
                        #else
                        .onChange(of: isAllSelected) { newValue in
                            for index in cacheOptions.indices where cacheOptions[index].isAvailable {
                                cacheOptions[index].isSelected = newValue
                            }
                        }
                        #endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Cache Options List
                    ForEach($cacheOptions) { $option in
                        CacheOptionRow(option: $option)
                            .opacity(option.isAvailable ? 1 : 0.6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            Divider()
            
            VStack(spacing: 12) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let date = lastCleanedDate {
                    Text("Last cleaned: \(date.formatted(.dateTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: cleanSelectedCaches) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Clean Selected")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("CleanSelectedButton")
                .disabled(isLoading || !cacheOptions.contains { $0.isSelected })
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 320, height: 500)
        .task {
            await checkAvailableCommands()
        }
    }
    
    private func findCommandPath(_ command: String) async throws -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "which \(command)"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        #if DEBUG
        Logger.debug("Finding path for command: \(command)")
        Logger.debug("Shell: \(process.executableURL?.path ?? "")")
        Logger.debug("Arguments: \(process.arguments?.joined(separator: " ") ?? "")")
        #endif
        
        try process.run()
        process.waitUntilExit()
        
        let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        #if DEBUG
        Logger.command("which \(command)", output: output)
        #endif
        
        if process.terminationStatus == 0 {
            return output
        }
        return nil
    }
    
    private func getVersionCheckCommand(for option: CacheOption) -> String {
        switch option.commandName {
        case "npm":
            // For npm, just check if the command exists since version check requires node
            return "command -v npm"
        case "docker":
            return "docker info"
        case "pod":
            return "command -v pod"
        case "brew":
            return "command -v brew"
        default:
            return "command -v \(option.commandName)"
        }
    }
    
    internal func executeCommand(_ command: String) async throws {
        let process = Process()
        let pipe = Pipe()
        
        var env = ProcessInfo.processInfo.environment
        // Include Homebrew paths for both Intel and Apple Silicon Macs
        let path = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = path
        
        // Add Homebrew's library path
        env["DYLD_LIBRARY_PATH"] = "/opt/homebrew/lib:/usr/local/lib"
        
        #if DEBUG
        Logger.debug("Executing command: \(command)")
        Logger.debug("PATH: \(path)")
        Logger.debug("DYLD_LIBRARY_PATH: \(env["DYLD_LIBRARY_PATH"] ?? "")")
        Logger.debug("Shell: /bin/zsh")
        #endif
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        process.environment = env
        
        try process.run()
        process.waitUntilExit()
        
        let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(data: data, encoding: .utf8)
        
        #if DEBUG
        Logger.command(command, output: output)
        Logger.debug("Exit status: \(process.terminationStatus)")
        #endif
        
        if process.terminationStatus != 0 {
            if let output = output {
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: output])
            }
        }
    }
    
    private func checkAvailableCommands() async {
        for index in cacheOptions.indices {
            let option = cacheOptions[index]
            
            // Skip check for options that use cleanAction
            if option.cleanAction != nil {
                cacheOptions[index].isAvailable = true
                continue
            }
            
            if option.commandName == "rm" {
                continue
            }
            
            #if DEBUG
            Logger.debug("Checking availability for: \(option.title)")
            #endif
            
            do {
                if let commandPath = try await findCommandPath(option.commandName) {
                    #if DEBUG
                    Logger.debug("Found path for \(option.title): \(commandPath)")
                    #endif
                    
                    cacheOptions[index].fullPath = commandPath
                    // Use the specific check command instead of --version
                    try await executeCommand(getVersionCheckCommand(for: option))
                    
                    cacheOptions[index].isAvailable = true
                    cacheOptions[index].error = nil
                    
                    #if DEBUG
                    Logger.debug("\(option.title) is available")
                    #endif
                } else {
                    cacheOptions[index].isAvailable = false
                    cacheOptions[index].error = "\(option.title) is not installed"
                    
                    #if DEBUG
                    Logger.error("\(option.title) path not found")
                    #endif
                }
            } catch {
                cacheOptions[index].isAvailable = false
                cacheOptions[index].error = "\(option.title) is not working properly or not running"
                
                #if DEBUG
                Logger.error("\(option.title) check failed", error: error)
                #endif
            }
        }
    }
    
    private func cleanSelectedCaches() {
        isLoading = true
        errorMessage = nil
        
        Task {
            for option in cacheOptions where option.isSelected {
                if !option.isAvailable && option.commandName != "" {
                    continue
                }
                
                do {
                    if let cleanAction = option.cleanAction {
                        try await cleanAction()
                    } else {
                        let fullCommand: String
                        if let path = option.fullPath {
                            fullCommand = "\(path) \(option.command)"
                        } else {
                            fullCommand = "\(option.commandName) \(option.command)"
                        }
                        try await executeCommand(fullCommand)
                    }
                } catch {
                    await MainActor.run {
                        if let currentError = errorMessage {
                            errorMessage = currentError + "\n" + option.title + ": " + (option.error ?? error.localizedDescription)
                        } else {
                            errorMessage = option.title + ": " + (option.error ?? error.localizedDescription)
                        }
                    }
                }
            }
            
            await MainActor.run {
                isLoading = false
                lastCleanedDate = Date()
            }
        }
    }
    
    private func refreshTools() {
        guard !isLoading else { return }
        
        isRefreshing = true
        errorMessage = nil
        
        Task {
            await checkAvailableCommands()
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

struct CacheOptionRow: View {
    @Binding var option: CacheOption
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $option.isSelected)
                .toggleStyle(.checkbox)
                .disabled(!option.isAvailable)
                .accessibilityIdentifier(option.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .font(.system(.body, weight: .medium))
                Text(option.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let error = option.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if option.isAvailable {
                option.isSelected.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}
