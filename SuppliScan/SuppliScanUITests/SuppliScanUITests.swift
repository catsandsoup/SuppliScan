// SuppliScanUITests.swift
// SuppliScanUITests

import XCTest

@MainActor
final class SuppliScanUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenLaunchesWithPrimaryActions() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["SuppliScan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Scan Label"].exists)
        XCTAssertTrue(app.buttons["Enter Manually"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }
}
