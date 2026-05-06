import XCTest

final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-mockData"]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "Tab bar never appeared")

        // Give the today fetch a beat to settle (mock returns instantly).
        usleep(1_500_000)
        capture("01-today")

        let buttons = tabBar.buttons
        if buttons.count >= 4 {
            buttons.element(boundBy: 1).tap()
            usleep(1_200_000)
            capture("02-forecast")

            buttons.element(boundBy: 2).tap()
            usleep(1_200_000)
            capture("03-character")

            buttons.element(boundBy: 3).tap()
            usleep(1_200_000)
            capture("04-profile")
        }
    }

    private func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
