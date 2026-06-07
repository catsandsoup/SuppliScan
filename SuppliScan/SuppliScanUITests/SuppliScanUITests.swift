// SuppliScanUITests.swift
// SuppliScanUITests

import XCTest

@MainActor
final class SuppliScanUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTabBarLaunchesWithAllTabs() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Scan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Analysis"].exists)
        XCTAssertTrue(app.tabBars.buttons["History"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    func testScanTabShowsImportButton() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Scan"].tap()
        XCTAssertTrue(app.buttons["Import Label Photo"].waitForExistence(timeout: 5))
    }
}
