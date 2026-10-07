import XCTest

final class LocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSimplifiedChineseWelcomeAndMenus() {
        checkWelcome(language: "zh-Hans", locale: "zh_CN", create: "创建画布", layerMenu: "图层", languageMenu: "语言")
    }

    @MainActor
    func testTraditionalChineseWelcomeAndMenus() {
        checkWelcome(language: "zh-Hant", locale: "zh_TW", create: "建立版面", layerMenu: "圖層", languageMenu: "語言")
    }

    @MainActor
    private func checkWelcome(language: String, locale: String, create: String, layerMenu: String, languageMenu: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                               "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        defer { app.terminate() }
        let button = app.buttons["createCanvas"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        XCTAssertEqual(button.label, create)
        XCTAssertTrue(app.textFields["widthInput"].exists)
        XCTAssertTrue(app.textFields["heightInput"].exists)
        XCTAssertTrue(app.menuBarItems[layerMenu].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Welcome-\(language)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.menuBarItems[layerMenu].click()
        let menuScreenshot = XCTAttachment(screenshot: app.screenshot())
        menuScreenshot.name = "Layer-menu-\(language)"
        menuScreenshot.lifetime = .keepAlways
        add(menuScreenshot)
        app.typeKey(.escape, modifierFlags: [])
        app.menuBarItems["Compositor"].click()
        XCTAssertTrue(app.menuItems[languageMenu].exists)
        app.menuItems[languageMenu].click()
        XCTAssertTrue(app.menuItems["English"].exists)
        XCTAssertTrue(app.menuItems["简体中文"].exists)
        XCTAssertTrue(app.menuItems["繁體中文"].exists)
        let languageScreenshot = XCTAttachment(screenshot: app.screenshot())
        languageScreenshot.name = "Language-menu-\(language)"
        languageScreenshot.lifetime = .keepAlways
        add(languageScreenshot)
        app.typeKey(.escape, modifierFlags: [])
        app.typeKey(.escape, modifierFlags: [])
    }
}
