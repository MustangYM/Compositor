import XCTest
import AppKit
@testable import Compositor

final class LocalizationTests: XCTestCase {
    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }

    func testChinesePhotoshopTerminology() throws {
        let simplified = try bundle("zh-Hans")
        let traditional = try bundle("zh-Hant")
        XCTAssertEqual(L10n.text("Multiply", bundle: simplified), "正片叠底")
        XCTAssertEqual(L10n.text("Screen", bundle: simplified), "滤色")
        XCTAssertEqual(L10n.text("Layer Mask", bundle: simplified), "图层蒙版")
        XCTAssertEqual(L10n.text("Clone Stamp", bundle: simplified), "仿制图章")
        XCTAssertEqual(L10n.text("Multiply", bundle: traditional), "色彩增值")
        XCTAssertEqual(L10n.text("Layer Mask", bundle: traditional), "圖層遮色片")
        XCTAssertEqual(L10n.text("Light", bundle: simplified), "光线")
        XCTAssertEqual(L10n.text("Light Color", bundle: simplified), "亮色")
        XCTAssertEqual(L10n.text("Canvas Extension", bundle: traditional), "版面延伸")
        XCTAssertEqual(L10n.text("Parametric", bundle: traditional), "參數")
    }

    func testInterpolationReordersArgumentsWithoutInterpretingUserContent() throws {
        let bundle = try bundle("zh-Hans")
        let shortcut = "⌘S"
        let first = "A %3$@ %@ 100%"
        let second = "B"
        XCTAssertEqual(L10n.tr("\(shortcut) is assigned to both \(first) and \(second).", bundle: bundle),
                       "\(first) 和 \(second) 均使用了快捷键 \(shortcut)。")
        let file = "旅行 100% %1$@.comp"
        XCTAssertEqual(L10n.tr("Save changes to \(file)?", bundle: bundle), "要保存对“\(file)”的更改吗？")
    }

    func testUnknownKeysFallBackAndLiteralPercentsArePreserved() throws {
        let bundle = try bundle("zh-Hans")
        XCTAssertEqual(L10n.text("A future untranslated label", bundle: bundle), "A future untranslated label")
        XCTAssertEqual(L10n.tr("100% \("x") and \("y")", bundle: bundle), "100% x and y")
        XCTAssertEqual(L10n.tr("%", bundle: bundle), "%")
    }

    func testAllLanguagesArePackagedAndPluralized() throws {
        for language in ["en", "zh-Hans", "zh-Hant", "ja", "ko", "de", "fr", "es", "pt-BR"] {
            let localized = try bundle(language)
            XCTAssertFalse(L10n.text("Cancel", bundle: localized).isEmpty)
            for typeName in ["Compositor Project", "Compositor Layer", "Adobe Photoshop Document", "Adobe Photoshop Large Document"] {
                XCTAssertNotEqual(localized.localizedString(forKey: typeName, value: "__missing__", table: "InfoPlist"),
                                  "__missing__", "\(language): \(typeName)")
            }
            for count in [0, 1, 2, 20] {
                let title = L10n.moreTabs(count, bundle: localized)
                XCTAssertTrue(title.contains(String(count)), "\(language): \(title)")
                XCTAssertFalse(title.contains("%@"))
                XCTAssertFalse(title.contains("%lld"))
            }
        }
        let english = try bundle("en")
        XCTAssertEqual(L10n.moreTabs(1, bundle: english), "1 more tab")
        XCTAssertEqual(L10n.moreTabs(2, bundle: english), "2 more tabs")
        XCTAssertEqual(L10n.moreTabs(2, bundle: try bundle("zh-Hans")), "另有 2 个标签页")
    }

    func testLocalizedNamesDoNotChangeSerializedBlendModes() throws {
        let localized = try bundle("zh-Hans")
        for mode in LayerBlendMode.allCases {
            let encoded = try JSONEncoder().encode(mode)
            XCTAssertEqual(try JSONDecoder().decode(LayerBlendMode.self, from: encoded), mode)
            XCTAssertEqual(String(data: encoded, encoding: .utf8), "\"\(mode.rawValue)\"")
            XCTAssertNotEqual(L10n.text(mode.rawValue, bundle: localized), mode.rawValue)
        }
    }

    @MainActor
    func testShortcutsKeepStableIdentifiersAndLocalizedSearchTitles() {
        let save = ShortcutDefinition.all.first { $0.title == "Save" && $0.isMenu }
        XCTAssertEqual(save?.id, "Menus:Save")
        XCTAssertEqual(save?.localizedTitle, L10n.text("Save"))
        XCTAssertEqual(Set(ShortcutDefinition.all.map(\.id)).count, ShortcutDefinition.all.count)
        XCTAssertNil(ShortcutSettings.problem(in: [:]))
        let space = ShortcutChord(" ", 1)
        XCTAssertEqual(space.label, "⌘" + L10n.text("Space"))
        XCTAssertEqual(space.key, " ")
    }

    @MainActor
    func testLanguagePreferencePersistsWithoutChangingSystemLanguage() throws {
        let domain = "Compositor.LocalizationTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        var settings = LanguageSettings(defaults: defaults, domain: domain)
        XCTAssertEqual(settings.selection, "")
        settings.select("zh-Hans")
        XCTAssertEqual(defaults.persistentDomain(forName: domain)?["AppleLanguages"] as? [String], ["zh-Hans"])
        XCTAssertEqual(LanguageSettings(defaults: defaults, domain: domain).selection, "zh-Hans")
        settings.select("unsupported")
        XCTAssertEqual(settings.selection, "zh-Hans")
        settings.select("")
        XCTAssertNil(defaults.persistentDomain(forName: domain)?["AppleLanguages"])
        XCTAssertEqual(LanguageSettings(defaults: defaults, domain: domain).selection, "")
        defaults.set(["zh-Hant-TW"], forKey: "AppleLanguages")
        XCTAssertEqual(LanguageSettings(defaults: defaults, domain: domain).selection, "zh-Hant")
    }

    @MainActor
    func testDisplayEnumsHaveEntriesInEveryLanguage() throws {
        var keys = Set<String>()
        func include<T: RawRepresentable & CaseIterable>(_ type: T.Type) where T.RawValue == String {
            keys.formUnion(T.allCases.map(\.rawValue))
        }
        include(LayerBlendMode.self)
        include(FilterKind.self)
        include(AdjustmentKind.self)
        include(LayerEffectKind.self)
        include(LayerSampling.self)
        include(CanvasUnit.self)
        include(TrimBasedOn.self)
        include(SelectionMode.self)
        include(WandMode.self)
        include(LassoKind.self)
        include(BrushToolMode.self)
        include(BlurToolMode.self)
        include(SpotHealingMode.self)
        include(GradientStyle.self)
        include(GradientShape.self)
        include(ShapeKind.self)
        include(TextAlignment.self)
        include(DitherStyle.self)
        include(DitherPixelShape.self)
        include(DitherColors.self)
        include(BackgroundQuality.self)
        include(LevelsChannel.self)
        include(LevelsSample.self)
        include(LevelsAuto.self)
        include(ColorRange.self)
        include(HueSampleMode.self)
        include(CameraRawWhiteBalance.self)
        include(CameraRawGlowStyle.self)
        include(CameraRawVignetteStyle.self)
        include(CameraRawCurvePage.self)
        include(CameraRawPointChannel.self)
        include(CameraRawMixerPage.self)
        include(CameraRawMixerTab.self)
        include(CameraRawGradePage.self)
        include(CameraRawUprightMode.self)
        include(CameraRawProjection.self)
        include(CameraRawProcessVersion.self)
        for language in LanguageSettings.languages {
            let localized = try bundle(language.id)
            for key in keys {
                XCTAssertNotEqual(localized.localizedString(forKey: key, value: "__missing__", table: "Localizable"),
                                  "__missing__", "\(language.id): \(key)")
            }
        }
    }

}
