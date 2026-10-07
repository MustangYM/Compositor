import Foundation

/// UI text is localized independently of document values, shortcut IDs, and user content.
nonisolated enum L10n {
    static func text(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func moreTabs(_ count: Int, bundle: Bundle = .main) -> String {
        String.localizedStringWithFormat(text("%lld more tabs", bundle: bundle), Int64(count))
    }

    static func tr(_ message: Message, bundle: Bundle = .main) -> String {
        let template = text(message.key, bundle: bundle)
        // Replace numbered tokens in one pass: arguments may themselves contain tokens or percent signs.
        var result = ""
        var remaining = template[...]
        while let start = remaining.firstIndex(of: "%") {
            result += remaining[..<start]
            let tail = remaining[start...]
            if let end = tail.firstIndex(of: "@"),
               tail[..<end].hasSuffix("$"),
               let number = Int(tail.dropFirst().prefix(upTo: tail.index(before: end))),
               message.arguments.indices.contains(number - 1) {
                result += message.arguments[number - 1]
                remaining = tail[tail.index(after: end)...]
            } else {
                result += "%"
                remaining = tail.dropFirst()
            }
        }
        return result + remaining
    }

    struct Message: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        let key: String
        let arguments: [String]
        init(stringLiteral value: String) { key = value; arguments = [] }
        init(stringInterpolation: StringInterpolation) {
            key = stringInterpolation.key
            arguments = stringInterpolation.arguments
        }
        struct StringInterpolation: StringInterpolationProtocol {
            var key = ""
            var arguments: [String] = []
            init(literalCapacity: Int, interpolationCount: Int) {
                key.reserveCapacity(literalCapacity)
                arguments.reserveCapacity(interpolationCount)
            }
            mutating func appendLiteral(_ literal: String) { key += literal }
            mutating func appendInterpolation<T>(_ value: T) {
                arguments.append(String(describing: value))
                key += "%\(arguments.count)$@"
            }
        }
    }
}
