import Foundation

/// Parse numeric text from custom text fields without treating decimal commas as grouping.
nonisolated enum LocalizedNumber {
    static func parse(_ input: String) -> Double? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.range(of: #"^[+-]?(?:[0-9]+(?:[.,][0-9]*)?|[.,][0-9]+)$"#,
                         options: .regularExpression) != nil,
              let value = Double(text.replacingOccurrences(of: ",", with: ".")), value.isFinite else { return nil }
        return value
    }

    static func format(_ value: Double, maximumFractionDigits: Int = 2, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
