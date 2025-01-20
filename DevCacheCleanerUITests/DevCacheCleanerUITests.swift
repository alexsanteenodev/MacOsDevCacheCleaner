//
//  DevCacheCleanerUITests.swift
//  DevCacheCleanerUITests
//
//  Created by Oleksandr Hanhaliuk on 19/01/2025.
//

import XCTest

final class DevCacheCleanerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        app.launch()
        
        // Click on the status bar item to show the window
        let statusItem = app.statusItems["Clean Cache"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 1), "Status item not found")
        statusItem.click()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testMainUIElements() throws {
        // Wait for popover to appear
        let popover = app.popovers.firstMatch
        XCTAssertTrue(popover.waitForExistence(timeout: 1))
        
        // Find Docker checkbox
        let dockerCheckbox = app.checkBoxes["Docker"]
        XCTAssertTrue(dockerCheckbox.waitForExistence(timeout: 1))
        
        // Find clean button
        let cleanButton = app.buttons["CleanSelectedButton"]
        XCTAssertTrue(cleanButton.waitForExistence(timeout: 1))
        XCTAssertFalse(cleanButton.isEnabled) // Should be disabled when no options selected
        
        // Select Docker and verify button becomes enabled
        dockerCheckbox.click()
        XCTAssertTrue(cleanButton.isEnabled)
    }
    
    func testCacheOptionSelection() throws {
        let dockerCheckbox = app.checkBoxes["Docker"]
        XCTAssertTrue(dockerCheckbox.waitForExistence(timeout: 1))
        
        // Select Docker option
        XCTAssertEqual(dockerCheckbox.value as? Int, 0)
        dockerCheckbox.click()
        XCTAssertEqual(dockerCheckbox.value as? Int, 1)
        
        // Deselect Docker option
        dockerCheckbox.click()
        XCTAssertEqual(dockerCheckbox.value as? Int, 0)
    }
    
    func testCleanButtonState() throws {
        let cleanButton = app.buttons["CleanSelectedButton"]
        let dockerCheckbox = app.checkBoxes["Docker"]
        
        XCTAssertTrue(cleanButton.waitForExistence(timeout: 1))
        XCTAssertTrue(dockerCheckbox.waitForExistence(timeout: 1))
        
        XCTAssertFalse(cleanButton.isEnabled) // Should be disabled when no options selected
        
        // Select an option
        dockerCheckbox.click()
        XCTAssertTrue(cleanButton.isEnabled) // Should be enabled when an option is selected
        
        // Deselect the option
        dockerCheckbox.click()
        XCTAssertFalse(cleanButton.isEnabled) // Should be disabled again
    }
    
    func testSelectAllButton() throws {
        let selectAllCheckbox = app.checkBoxes["SelectAllButton"]
        XCTAssertTrue(selectAllCheckbox.waitForExistence(timeout: 1))
        
        // Test select all functionality
        selectAllCheckbox.click()
        
        // Verify all options are selected
        XCTAssertEqual(app.checkBoxes["Docker"].value as? Int, 1)
        XCTAssertEqual(app.checkBoxes["Xcode"].value as? Int, 1)
        XCTAssertEqual(app.checkBoxes["Homebrew"].value as? Int, 1)
        XCTAssertEqual(app.checkBoxes["NPM"].value as? Int, 1)
        XCTAssertEqual(app.checkBoxes["CocoaPods"].value as? Int, 1)
        XCTAssertEqual(app.checkBoxes["Gradle"].value as? Int, 1)
    }
    
    func testCleaningProcess() throws {
        let libraryCheckbox = app.checkBoxes["General Library Cache"]
        let cleanButton = app.buttons["CleanSelectedButton"]
        
        XCTAssertTrue(libraryCheckbox.waitForExistence(timeout: 1))
        XCTAssertTrue(cleanButton.waitForExistence(timeout: 1))
        
        // Select Library Cache option
        libraryCheckbox.click()
        XCTAssertTrue(cleanButton.isEnabled)
        XCTAssertEqual(libraryCheckbox.value as? Int, 1)
        
        // Start cleaning
        cleanButton.click()
        
        // Give it some time to complete
        Thread.sleep(forTimeInterval: 5.0)
        
        // Verify the state after cleaning
        XCTAssertTrue(cleanButton.isEnabled)
        XCTAssertEqual(libraryCheckbox.value as? Int, 1)
    }
    func testMultipleOptionsClean() throws {
        // Select multiple options
        let homebrewCheckbox = app.checkBoxes["Homebrew"]
        let npmCheckbox = app.checkBoxes["NPM"]
        let cleanButton = app.buttons["CleanSelectedButton"]
        
        XCTAssertTrue(homebrewCheckbox.waitForExistence(timeout: 1))
        XCTAssertTrue(npmCheckbox.waitForExistence(timeout: 1))
        XCTAssertTrue(cleanButton.waitForExistence(timeout: 1))
        
        // Select options
        homebrewCheckbox.click()
        npmCheckbox.click()
        
        // Verify both are selected
        XCTAssertEqual(homebrewCheckbox.value as? Int, 1)
        XCTAssertEqual(npmCheckbox.value as? Int, 1)
        
        // Start cleaning
        cleanButton.click()
        
        // Give it some time to complete
        Thread.sleep(forTimeInterval: 5.0)
        
        // Verify the state after cleaning
        XCTAssertTrue(cleanButton.isEnabled)
        XCTAssertEqual(homebrewCheckbox.value as? Int, 1)
        XCTAssertEqual(npmCheckbox.value as? Int, 1)
    }
    
    func testToolAvailabilityCheck() throws {
        // Check Docker availability
        let dockerCheckbox = app.checkBoxes["Docker"]
        XCTAssertTrue(dockerCheckbox.waitForExistence(timeout: 1))
        
        // Check if unavailable tools show error message
        let errorTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'not installed' OR label CONTAINS 'not working properly'"))
        
        // If any tool is unavailable, there should be an error message
        if dockerCheckbox.isEnabled == false {
            XCTAssertGreaterThan(errorTexts.count, 0)
        }
    }
}
