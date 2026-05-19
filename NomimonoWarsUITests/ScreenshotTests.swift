import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for content to load
        sleep(5)

        // Tab 1: 新商品 (default tab)
        takeScreenshot(named: "01_shinshōhin")

        // Tab 2: ランキング
        let rankingTab = app.buttons["ランキング"]
        if rankingTab.waitForExistence(timeout: 3) {
            rankingTab.tap()
            sleep(3)
            takeScreenshot(named: "02_ranking")
        }

        // Tab 3: ニュース
        let newsTab = app.buttons["ニュース"]
        if newsTab.waitForExistence(timeout: 3) {
            newsTab.tap()
            sleep(3)
            takeScreenshot(named: "03_news")
        }

        // Tab 4: 飲みログ
        let logTab = app.buttons["飲みログ"]
        if logTab.waitForExistence(timeout: 3) {
            logTab.tap()
            sleep(2)
            takeScreenshot(named: "04_nomilog")
        }

        // Tab 5: 統計
        let statsTab = app.buttons["統計"]
        if statsTab.waitForExistence(timeout: 3) {
            statsTab.tap()
            sleep(2)
            takeScreenshot(named: "05_stats")
        }

        // Tab 6: 保存
        let bookmarksTab = app.buttons["保存"]
        if bookmarksTab.waitForExistence(timeout: 3) {
            bookmarksTab.tap()
            sleep(2)
            takeScreenshot(named: "06_bookmarks")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
