// SuppliScanUITests.swift
// SuppliScanUITests

import XCTest

final class SuppliScanUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabBarLaunchesWithAllTabs() throws {
        let app = launchApp()

        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Scan"].exists)
        XCTAssertTrue(app.buttons["History"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    @MainActor
    func testScanTabShowsImportButton() throws {
        let app = launchApp(startTab: "scan")

        XCTAssertTrue(app.buttons["Import Label Photo"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppStoreScreenshotJourney() throws {
        guard shouldCaptureAppStoreScreenshots else {
            throw XCTSkip("Run Tools/capture_app_store_screenshots.sh to export App Store screenshots.")
        }

        let outputURL = screenshotOutputDirectory()
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let app = launchApp(seedSample: true)
        XCTAssertTrue(app.staticTexts["SUPPLISCAN"].waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "01-home", in: outputURL)

        app.buttons["Scan"].tap()
        XCTAssertTrue(app.buttons["Import Label Photo"].waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "02-scan", in: outputURL)

        app.buttons["History"].tap()
        let historyRecord = app.buttons.containing(.staticText, identifier: "Advanced Multivitamin Pro").firstMatch
        XCTAssertTrue(historyRecord.waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "03-history", in: outputURL)

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "04-settings", in: outputURL)

        app.buttons["Home"].tap()
        let recentRecord = app.buttons.containing(.staticText, identifier: "Advanced Multivitamin Pro").firstMatch
        XCTAssertTrue(recentRecord.waitForExistence(timeout: 5))
        recentRecord.tap()

        XCTAssertTrue(app.staticTexts["Safety"].waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "05-report", in: outputURL)

        let interactionsTab = app.buttons["Interactions"].firstMatch
        XCTAssertTrue(interactionsTab.waitForExistence(timeout: 5))
        interactionsTab.tap()
        waitForUIToSettle()
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.staticTexts["Potential Interactions"].waitForExistence(timeout: 5))
        try saveScreenshot(of: app, named: "06-interactions", in: outputURL)
    }

    @MainActor
    @discardableResult
    private func launchApp(seedSample: Bool = false, startTab: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        if seedSample {
            app.launchArguments.append("-seedSample")
        }
        if let startTab {
            app.launchArguments += ["-startTab", startTab]
        }
        app.launch()
        return app
    }

    private func screenshotOutputDirectory() -> URL {
        if let outputDirectory = ProcessInfo.processInfo.environment["APP_STORE_SCREENSHOT_DIR"],
           !outputDirectory.isEmpty {
            return URL(fileURLWithPath: outputDirectory, isDirectory: true)
        }

        return repositoryRoot
            .appending(path: "Marketing/AppStore/Screenshots/raw/6.9-inch", directoryHint: .isDirectory)
    }

    private var shouldCaptureAppStoreScreenshots: Bool {
        if ProcessInfo.processInfo.environment["APP_STORE_SCREENSHOT_DIR"]?.isEmpty == false {
            return true
        }
        return FileManager.default.fileExists(atPath: appStoreCaptureSentinel.path)
    }

    private var appStoreCaptureSentinel: URL {
        repositoryRoot
            .appending(path: ".asc/capture-screenshots.enabled", directoryHint: .notDirectory)
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    @MainActor
    private func saveScreenshot(of app: XCUIApplication, named name: String, in directory: URL) throws {
        let screenshot = app.screenshot()
        let fileURL = directory.appending(path: "\(name).png")
        try screenshot.pngRepresentation.write(to: fileURL, options: .atomic)

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForUIToSettle(seconds: TimeInterval = 0.8) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
