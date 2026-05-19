import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        // Reset authorization to prevent ATT dialog
        app.launchArguments += ["-ATT_SKIP"]
        app.resetAuthorizationStatus(for: .userTracking)
        app.launch()

        // Handle any system dialogs automatically
        addUIInterruptionMonitor(withDescription: "System Dialog") { alert in
            for label in ["Allow", "許可", "OK", "Don't Allow", "許可しない"] {
                let btn = alert.buttons[label]
                if btn.exists {
                    btn.tap()
                    return true
                }
            }
            return false
        }

        // Wait for content to load
        sleep(8)

        // Interact to trigger any pending interruption monitors
        if app.windows.firstMatch.exists {
            app.windows.firstMatch.tap()
        }
        sleep(3)

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

    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let image = screenshot.image

        // Render without alpha channel (ASC rejects PNGs with transparency)
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
