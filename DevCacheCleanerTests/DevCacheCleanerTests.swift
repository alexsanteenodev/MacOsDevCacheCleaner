//
//  DevCacheCleanerTests.swift
//  DevCacheCleanerTests
//
//  Created by Oleksandr Hanhaliuk on 19/01/2025.
//

import XCTest
@testable import DevCacheCleaner

final class DevCacheCleanerTests: XCTestCase {
    var fileManager: FileManager!
    var testDirectory: URL!
    var contentView: ContentView!
    
    override func setUpWithError() throws {
        super.setUp()
        fileManager = FileManager.default
        testDirectory = fileManager.temporaryDirectory.appendingPathComponent("DevCacheCleanerTests")
        try? fileManager.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        contentView = ContentView()
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: testDirectory)
        contentView = nil
        super.tearDown()
    }
    
    func testDockerCacheOption() {
        let option = CacheOption(title: "Docker", 
                               description: "Clean Docker system and unused images", 
                               command: "",
                               commandName: "")
        
        XCTAssertEqual(option.title, "Docker")
        XCTAssertEqual(option.description, "Clean Docker system and unused images")
        XCTAssertFalse(option.isSelected)
        XCTAssertTrue(option.isAvailable)
    }
    
    func testXcodeCacheCleaning() async throws {
        // Create test Xcode cache directories
        let derivedData = testDirectory.appendingPathComponent("DerivedData")
        let archives = testDirectory.appendingPathComponent("Archives")
        
        try fileManager.createDirectory(at: derivedData, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: archives, withIntermediateDirectories: true)
        
        // Create some test files
        try "test".write(to: derivedData.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        try "test".write(to: archives.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        
        let option = CacheOption(title: "Xcode", 
                               description: "Clean Xcode derived data and archives",
                               command: "",
                               commandName: "") {
            // Test implementation
            if FileManager.default.fileExists(atPath: derivedData.path) {
                try FileManager.default.removeItem(at: derivedData)
            }
            if FileManager.default.fileExists(atPath: archives.path) {
                try FileManager.default.removeItem(at: archives)
            }
        }
        
        try await option.cleanAction?()
        
        XCTAssertFalse(fileManager.fileExists(atPath: derivedData.path))
        XCTAssertFalse(fileManager.fileExists(atPath: archives.path))
    }
    
    func testHomebrewCacheOption() {
        let option = CacheOption(title: "Homebrew",
                               description: "Clean Homebrew cache",
                               command: "",
                               commandName: "")
        
        XCTAssertEqual(option.title, "Homebrew")
        XCTAssertEqual(option.description, "Clean Homebrew cache")
        XCTAssertFalse(option.isSelected)
        XCTAssertTrue(option.isAvailable)
    }
    
    func testNPMCacheCleaning() async throws {
        // Create test NPM cache directory
        let npmCache = testDirectory.appendingPathComponent("npm_cache")
        try fileManager.createDirectory(at: npmCache, withIntermediateDirectories: true)
        try "test".write(to: npmCache.appendingPathComponent("cache.txt"), atomically: true, encoding: .utf8)
        
        let option = CacheOption(title: "NPM",
                               description: "Clean NPM cache",
                               command: "",
                               commandName: "") {
            if FileManager.default.fileExists(atPath: npmCache.path) {
                try FileManager.default.removeItem(at: npmCache)
            }
        }
        
        try await option.cleanAction?()
        XCTAssertFalse(fileManager.fileExists(atPath: npmCache.path))
    }
    
    // Test cache option initialization
    func testCacheOptionInitialization() throws {
        let option = CacheOption(
            title: "Test Cache",
            description: "Test Description",
            command: "test-command",
            commandName: "test"
        )
        
        XCTAssertEqual(option.title, "Test Cache")
        XCTAssertEqual(option.description, "Test Description")
        XCTAssertEqual(option.command, "test-command")
        XCTAssertEqual(option.commandName, "test")
        XCTAssertFalse(option.isSelected)
        XCTAssertTrue(option.isAvailable)
        XCTAssertNil(option.error)
    }
    
    // Test Docker cache cleaning action
    func testDockerCacheCleanAction() async throws {
        let dockerOption = await contentView.cacheOptions.first { $0.title == "Docker" }
        XCTAssertNotNil(dockerOption)
        
        guard let cleanAction = dockerOption?.cleanAction else {
            XCTFail("Docker clean action is nil")
            return
        }
        
        // Test if Docker is not installed
        if !FileManager.default.fileExists(atPath: "/Applications/Docker.app") {
            do {
                try await cleanAction()
                XCTFail("Should throw error when Docker is not installed")
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("Docker.app is not installed"))
            }
        }
    }
    
    // Test Homebrew cache cleaning action
    func testHomebrewCacheCleanAction() async throws {
        let brewOption = await contentView.cacheOptions.first { $0.title == "Homebrew" }
        XCTAssertNotNil(brewOption)
        
        guard let cleanAction = brewOption?.cleanAction else {
            XCTFail("Homebrew clean action is nil")
            return
        }
        
        // Create test cache files
        let fileManager = FileManager.default
        let testCachePath = "/opt/homebrew/Library/Homebrew/Cache/test.cache"
        
        try? "test data".write(toFile: testCachePath, atomically: true, encoding: .utf8)
        
        // Run clean action
        try await cleanAction()
        
        // Verify cache was cleaned
        XCTAssertFalse(fileManager.fileExists(atPath: testCachePath))
    }
    
    // Test Library cache cleaning action
    func testLibraryCacheCleanAction() async throws {
        let libraryOption = await contentView.cacheOptions.first { $0.title == "General Library Cache" }
        XCTAssertNotNil(libraryOption)
        
        guard let cleanAction = libraryOption?.cleanAction else {
            XCTFail("Library clean action is nil")
            return
        }
        
        // Create test cache file
        let fileManager = FileManager.default
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let testFile = cachesURL.appendingPathComponent("test.cache")
        
        try? "test data".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Run clean action
        try await cleanAction()
        
        // Verify cache was cleaned
        XCTAssertFalse(fileManager.fileExists(atPath: testFile.path))
    }
    
    // Test multiple cache selections
    func testMultipleCacheSelections() {
        // Create test options
        var option1 = CacheOption(title: "Test1", description: "Test1 Description", command: "", commandName: "")
        var option2 = CacheOption(title: "Test2", description: "Test2 Description", command: "", commandName: "")
        
        // Test initial state
        XCTAssertFalse(option1.isSelected)
        XCTAssertFalse(option2.isSelected)
        
        // Modify selections
        option1.isSelected = true
        option2.isSelected = true
        
        // Verify selections
        XCTAssertTrue(option1.isSelected)
        XCTAssertTrue(option2.isSelected)
    }
    
    // Test error handling
    func testErrorHandling() async {
        let option = CacheOption(
            title: "Test Cache",
            description: "Test Description",
            command: "invalid-command",
            commandName: "invalid"
        )
        
        // Test invalid command execution
        do {
            try await contentView.executeCommand("invalid-command")
            XCTFail("Should throw error for invalid command")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
