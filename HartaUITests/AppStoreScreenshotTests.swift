import XCTest
import UIKit

/// Opt-in capture workflow. Uses a dedicated simulator seeded by scripts/app-store-assets/prepare.py.
@MainActor
final class AppStoreScreenshotTests: XCTestCase {
    func testCaptureAppStoreScreens() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_APP_STORE_SCREENSHOTS"] == "1")
        let app = XCUIApplication()
        app.launchArguments = ["-mapStyle", "everyday", "-mapOverlays", "0"]
        app.launch()
        XCTAssertTrue(app.buttons["map.saved"].waitForExistence(timeout: 20))
        settle(8)
        capture("01-explore", app)
        app.buttons["map.saved"].tap()
        XCTAssertTrue(app.buttons["saved.place.demo-park"].waitForExistence(timeout: 5))
        settle(1)
        capture("02-your-places", app)
        app.buttons["saved.place.demo-park"].tap()
        XCTAssertTrue(app.buttons["place.go"].waitForExistence(timeout: 5))
        settle(15)
        capture("03-plan-a-visit", app)
        app.buttons["place.icon"].tap()
        XCTAssertTrue(app.navigationBars["Choose an icon"].waitForExistence(timeout: 5))
        settle(2)
        capture("04-make-it-yours", app)
        // The iPad set uses four scenes; the optional layers sheet is captured on iPhone.
        if UIDevice.current.userInterfaceIdiom == .pad { return }
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["map.layers"].waitForExistence(timeout: 15))
        app.buttons["map.layers"].tap()
        if !app.navigationBars["Map layers"].waitForExistence(timeout: 3) {
            app.buttons["map.layers"].tap()
        }
        XCTAssertTrue(app.navigationBars["Map layers"].waitForExistence(timeout: 5))
        settle(2)
        capture("05-explore-more", app)
    }

    private func settle(_ seconds: TimeInterval) {
        let rendering = expectation(description: "Allow map tiles and presentation to settle")
        rendering.isInverted = true
        wait(for: [rendering], timeout: seconds)
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
