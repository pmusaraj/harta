import XCTest

@MainActor
final class MapFlowTests: XCTestCase {
    func testEmptyMapTapDismissesSelectedPlace() {
        let app = XCUIApplication()
        for overlays in ["0", "8"] {
            app.launchArguments = ["-mapOverlays", overlays]
            app.launch()
            XCTAssertTrue(app.buttons["map.search"].waitForExistence(timeout: 15))
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
            XCTAssertTrue(app.buttons["place.save"].waitForExistence(timeout: 5))

            app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.25)).tap()

            XCTAssertTrue(app.buttons["place.save"].waitForNonExistence(timeout: 5))
            XCTAssertTrue(app.buttons["map.search"].isHittable)
            app.terminate()
        }
    }

    func testOptionalLayersPersist() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["map.layers"].waitForExistence(timeout: 15))
        app.buttons["map.layers"].tap()
        let clear = app.buttons["Turn off all layers"]
        if clear.isEnabled { clear.tap() }
        for key in ["chargers", "toilets", "parking", "cycling", "transit", "essentials"] {
            let toggle = app.switches["layers.\(key)"]
            if !toggle.isHittable { app.swipeUp() }
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            XCTAssertEqual(toggle.value as? String, "1")
        }
        let layersScreenshot = XCTAttachment(screenshot: app.screenshot())
        layersScreenshot.name = "Enabled map layers"
        layersScreenshot.lifetime = .keepAlways
        add(layersScreenshot)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["map.layers"].value as? String, "6 enabled")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["map.layers"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["map.layers"].value as? String, "6 enabled")
        app.buttons["map.settings"].tap()
        app.buttons["settings.style.quiet"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["map.layers"].value as? String, "6 enabled")
        XCTAssertFalse(app.staticTexts["The map couldn’t load. Check your connection and try again."].exists)
        app.buttons["map.layers"].tap()
        app.buttons["Turn off all layers"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["map.layers"].value as? String, "0 enabled")
        app.buttons["map.settings"].tap()
        app.buttons["settings.style.everyday"].tap()
        app.buttons["Done"].tap()
    }

    func testCompactSearchDismissesOutsideWithoutResults() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["map.search"].tap()
        XCTAssertTrue(app.textFields["search.input"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let panel = app.otherElements["search.panel"]
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        XCTAssertLessThan(panel.frame.height, 360)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Compact blurred search"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.typeText("Toronto")
        app.buttons["search.dismiss"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)).tap()
        XCTAssertTrue(app.buttons["map.search"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["search.input"].exists)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }

    func testMapStylesInLightAndDarkAppearance() {
        let device = XCUIDevice.shared
        let originalAppearance = device.appearance
        defer { device.appearance = originalAppearance }
        let app = XCUIApplication()
        app.launchArguments = ["-mapOverlays", "63"]
        app.launch()
        XCTAssertTrue(app.buttons["map.settings"].waitForExistence(timeout: 15))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["place.save"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        for appearance in [XCUIDevice.Appearance.light, .dark] {
            device.appearance = appearance
            for style in ["quiet", "walking", "explore", "everyday"] {
                app.buttons["map.settings"].tap()
                app.buttons["settings.style.\(style)"].tap()
                app.buttons["Done"].tap()
                XCTAssertTrue(app.buttons["map.settings"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.staticTexts["The map couldn’t load. Check your connection and try again."].exists)
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "\(style)-\(appearance == .dark ? "dark" : "light")"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
        }
    }

    func testMapSettingsPersist() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["map.settings"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["map.more"].exists)
        app.buttons["map.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        for style in ["quiet", "walking", "explore", "everyday"] {
            let row = app.buttons["settings.style.\(style)"]
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()
            XCTAssertEqual(row.value as? String, "Selected")
            app.buttons["Done"].tap()
            XCTAssertTrue(app.buttons["map.settings"].waitForExistence(timeout: 5))
            app.buttons["map.settings"].tap()
            XCTAssertEqual(app.buttons["settings.style.\(style)"].value as? String, "Selected")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Settings with Everyday selected"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["settings.style.explore"].tap()
        app.terminate()
        app.launch()
        app.buttons["map.settings"].tap()
        XCTAssertEqual(app.buttons["settings.style.explore"].value as? String, "Selected")
        app.buttons["settings.style.everyday"].tap()
        let credits = app.descendants(matching: .any).matching(identifier: "OpenFreeMap").firstMatch
        for _ in 0..<5 {
            if credits.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(credits.isHittable)
        app.buttons["Done"].tap()
    }

    // Explicitly opt in: this smoke test calls the public prototype routing service.
    func testLiveDirections() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_LIVE_ROUTING_TESTS"] == "1")
        let app = XCUIApplication()
        app.launch()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        app.buttons["place.go"].tap()
        XCTAssertTrue(app.buttons["navigation.end"].waitForExistence(timeout: 10))
        app.buttons["navigation.end"].tap()
        XCTAssertTrue(app.buttons["place.go"].waitForExistence(timeout: 5))
        app.buttons["place.directions"].tap()
        XCTAssertTrue(app.buttons["directions.summary"].waitForExistence(timeout: 40))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "In-app walking directions"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.segmentedControls.buttons["Drive"].tap()
        XCTAssertTrue(app.buttons["directions.summary"].waitForExistence(timeout: 40))
        app.segmentedControls.buttons["Cycle"].tap()
        XCTAssertTrue(app.buttons["directions.summary"].waitForExistence(timeout: 40))
        app.buttons["directions.start"].tap()
        let instruction = app.staticTexts["navigation.instruction"]
        XCTAssertTrue(instruction.waitForExistence(timeout: 40))
        let ready = NSPredicate(format: "label != %@ AND label != %@", "Finding your location…", "Preparing your route…")
        expectation(for: ready, evaluatedWith: instruction)
        waitForExpectations(timeout: 40)
        let navigation = XCTAttachment(screenshot: app.screenshot())
        navigation.name = "Turn-by-turn navigation"
        navigation.lifetime = .keepAlways
        add(navigation)
        let voice = app.buttons["navigation.mute"]
        let originalVoiceLabel = voice.label
        voice.tap()
        let chosenVoiceLabel = originalVoiceLabel == "Unmute" ? "Mute" : "Unmute"
        XCTAssertEqual(voice.label, chosenVoiceLabel)
        app.buttons["navigation.end"].tap()
        XCTAssertTrue(app.buttons["directions.start"].waitForExistence(timeout: 5))
        app.buttons["directions.start"].tap()
        XCTAssertTrue(voice.waitForExistence(timeout: 5))
        XCTAssertEqual(voice.label, chosenVoiceLabel)
        voice.tap()
        XCTAssertEqual(voice.label, originalVoiceLabel)
        app.buttons["navigation.end"].tap()
        app.buttons["directions.origin"].tap()
        app.buttons["Search starting point"].tap()
        XCTAssertTrue(app.textFields["search.input"].waitForExistence(timeout: 5))
    }

    func testPinSaveAndRestore() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["map.settings"].waitForExistence(timeout: 15))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        let save = app.buttons["place.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        if save.label == "Saved" { save.tap() }
        save.tap()
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        app.buttons["map.saved"].tap()
        let pin = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "saved.place.")).firstMatch
        XCTAssertTrue(pin.waitForExistence(timeout: 5))
        let savedIdentifier = pin.identifier
        pin.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.label, "Saved")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Saved place details"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["Done"].tap()
        app.buttons["map.saved"].tap()
        pin.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.buttons[savedIdentifier].exists)
    }

    func testSavedSearchShortcut() {
        let app = XCUIApplication()
        app.launch()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        let save = app.buttons["place.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        if save.label != "Saved" { save.tap() }
        app.buttons["Done"].tap()
        app.buttons["map.search"].tap()
        let clearRecents = app.buttons["Clear recent places"]
        if clearRecents.exists { clearRecents.tap() }
        let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "search.place.pin:")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.buttons["place.go"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["map.search"].tap()
        XCTAssertTrue(app.staticTexts["Recent"].waitForExistence(timeout: 5))
        let bookmark = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "search.save.pin:")).firstMatch
        bookmark.tap()
        XCTAssertTrue(bookmark.label.hasPrefix("Save "))
        bookmark.tap()
        XCTAssertTrue(bookmark.label.hasPrefix("Unsave "))
        bookmark.tap()
        app.buttons["search.close"].tap()
    }

    func testSearchAndEmptySavedPlaces() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["map.search"].tap()
        XCTAssertTrue(app.textFields["search.input"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.typeText("Toronto")
        XCTAssertEqual(app.textFields["search.input"].value as? String, "Toronto")
        app.buttons["search.close"].tap()
        app.buttons["map.saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved places"].waitForExistence(timeout: 5))
    }
}
