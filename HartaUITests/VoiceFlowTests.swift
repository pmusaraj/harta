import XCTest

@MainActor
final class VoiceFlowTests: XCTestCase {
    func testDeniedMicrophoneOffersTypedSearchWithoutTranscript() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .microphone)
        app.launch()
        XCTAssertTrue(app.buttons["map.search"].waitForExistence(timeout: 15))
        app.buttons["map.search"].tap()
        let microphone = app.buttons["search.microphone"]
        XCTAssertTrue(microphone.waitForExistence(timeout: 5))
        microphone.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["Don't Allow", "Don’t Allow"])).firstMatch
        XCTAssertTrue(deny.waitForExistence(timeout: 5))
        deny.tap()
        let error = app.staticTexts["search.voice.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("microphone access"))
        XCTAssertTrue(microphone.isEnabled)
        let input = app.textFields["search.input"]
        XCTAssertEqual(input.value as? String, "Place or address")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Voice search microphone recovery"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        input.tap()
        input.typeText("Library")
        XCTAssertTrue(error.waitForNonExistence(timeout: 5))
        XCTAssertEqual(input.value as? String, "Library")
        app.buttons["search.close"].tap()
        XCTAssertTrue(app.buttons["map.search"].waitForExistence(timeout: 5))
    }

    func testMicrophoneCaptureOnSupportedPhysicalDevice() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Requires on-device speech assets and a physical microphone.")
        #else
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["map.search"].waitForExistence(timeout: 15))
        app.buttons["map.search"].tap()
        let microphone = app.buttons["search.microphone"]
        XCTAssertTrue(microphone.waitForExistence(timeout: 5))
        microphone.tap()
        let listening = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Stop listening"), object: microphone)
        XCTAssertEqual(XCTWaiter.wait(for: [listening], timeout: 45), .completed)
        // The original crash happened as soon as the first real audio buffer arrived.
        let start = Date.now
        let capturing = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            Date.now.timeIntervalSince(start) > 2 && app.state == .runningForeground
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [capturing], timeout: 5), .completed)
        XCTAssertEqual(microphone.label, "Stop listening")
        microphone.tap()
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningForeground &&
                (!app.buttons["search.microphone"].exists || app.buttons["search.microphone"].isEnabled)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 40), .completed)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Physical device after microphone capture"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        #endif
    }


    func testTypedSportSearchIncludesSavedPlaceByIcon() {
        let app = XCUIApplication()
        app.launchArguments = ["-mapOverlays", "0"]
        app.launch()
        addUIInterruptionMonitor(withDescription: "Location recovery") { alert in
            if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
            return false
        }
        if app.alerts["Location"].waitForExistence(timeout: 2) { app.alerts["Location"].buttons["OK"].tap() }
        XCTAssertTrue(app.buttons["map.saved"].waitForExistence(timeout: 15))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        let save = app.buttons["place.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        if save.label == "Saved" { save.tap() }
        save.tap()
        app.buttons["Done"].tap()
        app.buttons["map.saved"].tap()
        let icon = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "saved.icon.pin:")).firstMatch
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        let placeID = String(icon.identifier.dropFirst("saved.icon.".count))
        icon.tap()
        let tennis = app.buttons["saved.icon.option.tennis"]
        if !tennis.isHittable { app.swipeUp() }
        XCTAssertTrue(tennis.waitForExistence(timeout: 5))
        tennis.tap()
        app.buttons["Done"].tap()
        app.buttons["map.search"].tap()
        let input = app.textFields["search.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("tennis\n")
        let result = app.buttons["search.place.\(placeID)"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.staticTexts["Saved"].exists)
        app.buttons["search.save.\(placeID)"].tap()
        app.buttons["search.close"].tap()
    }

}
