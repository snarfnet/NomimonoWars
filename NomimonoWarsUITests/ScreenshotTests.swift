import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        // Dismiss ATT dialog if it appears
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        } else {
            // Try Japanese button text
            let allowJP = springboard.buttons["許可"]
            if allowJP.waitForExistence(timeout: 2) {
                allowJP.tap()
            }
        }

        // Also handle any system alerts
        addUIInterruptionMonitor(withDescription: "System Alert") { alert in
            let allow = alert.buttons["Allow"]
            if allow.exists { allow.tap(); return true }
            let allowJP = alert.buttons["許可"]
            if allowJP.exists { allowJP.tap(); return true }
            return false
        }
        // Trigger the interruption monitor
        app.tap()

        // Wait for content to fully load
        sleep(10)

        // Tab 1: 新商品 (default tab)
        saveScreenshot(named: "01_new")

        // Tab 2: ランキング
        tapTab("ランキング", in: app)
        sleep(5)
        saveScreenshot(named: "02_ranking")

        // Tab 3: ニュース
        tapTab("ニュース", in: app)
        sleep(5)
        saveScreenshot(named: "03_news")

        // Tab 4: 飲みログ
        tapTab("飲みログ", in: app)
        sleep(3)
        saveScreenshot(named: "04_log")

        // Tab 5: 統計
        tapTab("統計", in: app)
        sleep(3)
        saveScreenshot(named: "05_stats")

        // Tab 6: 保存
        tapTab("保存", in: app)
        sleep(3)
        saveScreenshot(named: "06_bookmarks")

        // Write completion marker
        let marker = URL(fileURLWithPath: "/tmp/nomimonowars_screenshots_done")
        try? "done".write(to: marker, atomically: true, encoding: .utf8)
    }

    private func tapTab(_ label: String, in app: XCUIApplication) {
        // Scroll the tab bar to find the tab if needed
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            return
        }
        // Try staticTexts
        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 3) {
            text.tap()
            return
        }
        // Try scrolling horizontally in the tab bar area to reveal hidden tabs
        let tabBar = app.scrollViews.firstMatch
        if tabBar.exists {
            tabBar.swipeLeft()
            sleep(1)
            if button.waitForExistence(timeout: 2) {
                button.tap()
            }
        }
    }

    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let data = screenshot.pngRepresentation
        let path = "/tmp/nw_screenshot_\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
