import XCTest
@testable import Compositor

final class LocalizedNumberTests: XCTestCase {
    func testDecimalCommaAndPointAreParsedWithoutChangingMagnitude() {
        XCTAssertEqual(LocalizedNumber.parse("12,5"), 12.5)
        XCTAssertEqual(LocalizedNumber.parse("12.5"), 12.5)
        XCTAssertEqual(LocalizedNumber.parse("-0,25"), -0.25)
        XCTAssertEqual(LocalizedNumber.parse(" 3200 "), 3200)
        for invalid in ["12,5.0", "1,234.5", "12%", "NaN", "inf", "1e3", "12x"] {
            XCTAssertNil(LocalizedNumber.parse(invalid), invalid)
        }
    }

    func testDisplayUsesLocaleDecimalSeparatorWithoutGrouping() {
        XCTAssertEqual(LocalizedNumber.format(12.5, locale: Locale(identifier: "de_DE")), "12,5")
        XCTAssertEqual(LocalizedNumber.format(1234.5, locale: Locale(identifier: "fr_FR")), "1234,5")
        XCTAssertEqual(LocalizedNumber.format(12.5, locale: Locale(identifier: "en_US")), "12.5")
    }
}
