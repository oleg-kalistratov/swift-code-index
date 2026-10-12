import Foundation

/// A path pattern from `.swift-code-index.json`, matched against paths relative
/// to the project root with .gitignore-like rules: `*` and `?` stay within one
/// folder, `**` spans folders, a trailing `/` matches everything inside a folder,
/// and a pattern without a `/` matches a file name at any depth.
struct Glob {
    private let regex: NSRegularExpression

    init?(_ pattern: String) {
        var source = pattern.hasSuffix("/") ? pattern + "**" : pattern
        if !source.contains("/") {
            source = "**/" + source
        }
        var expression = "^"
        var index = source.startIndex
        while index < source.endIndex {
            let rest = source[index...]
            if rest.hasPrefix("**/") {
                expression += "(?:.*/)?"
                index = source.index(index, offsetBy: 3)
                continue
            }
            if rest.hasPrefix("**") {
                expression += ".*"
                index = source.index(index, offsetBy: 2)
                continue
            }
            switch source[index] {
            case "*": expression += "[^/]*"
            case "?": expression += "[^/]"
            default: expression += NSRegularExpression.escapedPattern(for: String(source[index]))
            }
            index = source.index(after: index)
        }
        expression += "$"
        guard let regex = try? NSRegularExpression(pattern: expression) else { return nil }
        self.regex = regex
    }

    func matches(_ relativePath: some StringProtocol) -> Bool {
        let path = String(relativePath)
        return regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)) != nil
    }
}
