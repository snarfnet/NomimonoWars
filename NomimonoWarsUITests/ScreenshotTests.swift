import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-SKIP_ATT"]
        app.launch()

        // Verify the app is actually running
        let isRunning = app.wait(for: .runningForeground, timeout: 30)
        XCTAssertTrue(isRunning, "App failed to launch or crashed")

        if !isRunning {
            // Try to relaunch
            app.launch()
            let retry = app.wait(for: .runningForeground, timeout: 30)
            XCTAssertTrue(retry, "App failed to launch on retry")
            if !retry { return }
        }

        // Wait for content to load
        sleep(10)

        // Verify app is still running after content load
        XCTAssertTrue(app.state == .runningForeground, "App crashed during content load")

        // Tab 1: 新商品 (default tab)
        saveScreenshot(named: "01_new", app: app)

        // Tab 2: ランキング
        tapTab("ランキング", in: app)
        sleep(5)
        saveScreenshot(named: "02_ranking", app: app)

        // Tab 3: ニュース
        tapTab("ニュース", in: app)
        sleep(5)
        saveScreenshot(named: "03_news", app: app)

        // Tab 4: 飲みログ
        tapTab("飲みログ", in: app)
        sleep(3)
        saveScreenshot(named: "04_log", app: app)

        // Tab 5: 統計
        tapTab("統計", in: app)
        sleep(3)
        saveScreenshot(named: "05_stats", app: app)

        // Tab 6: 保存
        tapTab("保存", in: app)
        sleep(3)
        saveScreenshot(named: "06_bookmarks", app: app)

        // Write completion marker
        let marker = URL(fileURLWithPath: "/tmp/nomimonowars_screenshots_done")
        try? "done".write(to: marker, atomically: true, encoding: .utf8)
    }

    private func tapTab(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            return
        }
        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 3) {
            text.tap()
        }
    }

    private func saveScreenshot(named name: String, app: XCUIApplication) {
        guard app.state == .runningForeground else {
            XCTFail("App not running when trying to capture \(name)")
            return
        }

        // Use XCUIScreen for full native resolution (app.screenshot() returns @1x)
        let screenshot = XCUIScreen.main.screenshot()
        let image = screenshot.image

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let opaqueImage = renderer.image { ctx in
            image.draw(at: .zero)
        }

        if let data = opaqueImage.pngData() {
            let path = "/tmp/nw_screenshot_\(name).png"
            try? data.write(to: URL(fileURLWithPath: path))
        }

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
