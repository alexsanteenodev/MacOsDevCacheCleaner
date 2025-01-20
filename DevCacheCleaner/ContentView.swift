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
    @State private var cacheOptions = [
        CacheOption(title: "Docker", 
                   description: "Clean Docker system and unused images", 
                   command: "system prune --all --force",
                   commandName: "docker"),
        CacheOption(title: "Homebrew", 
                   description: "Clean Homebrew cache", 
                   command: "cleanup -s",
                   commandName: "brew"),
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
                       
                       do {
                           // Clean DerivedData
                           if fileManager.fileExists(atPath: derivedDataURL.path) {
                               let derivedContents = try fileManager.contentsOfDirectory(at: derivedDataURL, 
                                                                                      includingPropertiesForKeys: nil)
                               for url in derivedContents {
                                   try? fileManager.removeItem(at: url)
                               }
                           }
                           
                           // Clean Archives
                           if fileManager.fileExists(atPath: archivesURL.path) {
                               let archiveContents = try fileManager.contentsOfDirectory(at: archivesURL, 
                                                                                       includingPropertiesForKeys: nil)
                               for url in archiveContents {
                                   try? fileManager.removeItem(at: url)
                               }
                           }
                       } catch {
                           throw error
                       }
                   }),
        CacheOption(title: "NPM", 
                   description: "Clean NPM cache", 
                   command: "cache clean --force",
                   commandName: "npm"),
        CacheOption(title: "CocoaPods", 
                   description: "Clean CocoaPods cache", 
                   command: "cache clean --all",
                   commandName: "pod"),
    ]
    
    @State private var isLoading = false
    @State private var lastCleanedDate: Date?
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dev Cache Cleaner")
                    .font(.headline)
                
                Spacer()
                
                Button(action: refreshTools) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .disabled(isLoading)
            }
            .padding(.top)
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach($cacheOptions) { $option in
                        CacheOptionRow(option: $option)
                            .opacity(option.isAvailable ? 1 : 0.6)
                    }
                }
                .padding(.horizontal)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
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
                } else {
                    Text("Clean Selected")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || !cacheOptions.contains { $0.isSelected })
            .padding(.bottom)
        }
        .frame(width: 300)
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
    
    private func executeCommand(_ command: String) async throws {
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
                cacheOptions[index].error = "\(option.title) is not working properly"
                
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Toggle("", isOn: $option.isSelected)
                    .toggleStyle(.checkbox)
                    .disabled(!option.isAvailable)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline)
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = option.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
