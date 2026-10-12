import Foundation
@preconcurrency import IndexStoreDB

/// Tells the project's own source files apart from its dependencies' sources,
/// which the index also holds once they have been built, and test code apart
/// from production code.
///
/// The root is the folder holding the .xcworkspace or .xcodeproj, or the package
/// directory itself. Swift packages resolved by Xcode live in DerivedData, outside
/// the root; CocoaPods, Carthage and SwiftPM checkouts sit inside it, so those
/// folders are excluded by name. An optional `.swift-code-index.json` in the root
/// adds `exclude` and `tests` path patterns (see `Glob`).
struct ProjectScope {
    static let configurationFileName = ".swift-code-index.json"

    let root: String
    /// Set when the configuration file exists but cannot be used; the defaults
    /// apply instead, and loadIndex reports this so results never change silently.
    let configurationProblem: String?
    private let excludePatterns: [Glob]
    private let testPatterns: [Glob]

    init(workspacePath: String) {
        let url = URL(fileURLWithPath: workspacePath).standardizedFileURL
        let isContainer = url.pathExtension == "xcworkspace" || url.pathExtension == "xcodeproj"
        root = isContainer ? url.deletingLastPathComponent().path : url.path

        let configuration = Self.readConfiguration(in: root)
        excludePatterns = configuration.exclude
        testPatterns = configuration.tests
        configurationProblem = configuration.problem
    }

    func contains(_ path: String) -> Bool {
        guard let relative = relativePath(path) else { return false }
        if Self.vendoredFolders.contains(where: { relative.hasPrefix($0) }) {
            return false
        }
        return !excludePatterns.contains { $0.matches(relative) }
    }

    /// Test targets are named `…Tests` by Xcode and SwiftPM convention; test
    /// doubles kept beside production code sit in folders such as `Mocks/`.
    func isTest(path: String, moduleName: String) -> Bool {
        if moduleName.hasSuffix("Tests") {
            return true
        }
        let relative = relativePath(path) ?? Substring(path)
        let folders = relative.split(separator: "/").dropLast()
        if folders.contains(where: { $0.hasSuffix("Tests") || Self.testDoubleFolders.contains(String($0)) }) {
            return true
        }
        return testPatterns.contains { $0.matches(relative) }
    }

    func isTest(_ occurrence: SymbolOccurrence) -> Bool {
        isTest(path: occurrence.location.path, moduleName: occurrence.location.moduleName)
    }
    
    /// Short summary for loadIndex, or nil when the project has no configuration file.
    var configurationSummary: String? {
        if let configurationProblem {
            return "Configuration problem: \(configurationProblem) Using the defaults."
        }
        guard FileManager.default.fileExists(atPath: configurationPath) else { return nil }
        return "Configuration: \(configurationPath) (\(excludePatterns.count) exclude, \(testPatterns.count) tests pattern(s))"
    }

    private var configurationPath: String {
        "\(root)/\(Self.configurationFileName)"
    }

    private func relativePath(_ path: String) -> Substring? {
        guard path.hasPrefix(root + "/") else { return nil }
        return path.dropFirst(root.count + 1)
    }

    private static let vendoredFolders = ["Pods/", "Carthage/", ".build/"]
    private static let testDoubleFolders: Set<String> = ["Mocks", "Fakes", "Stubs", "TestSupport", "TestHelpers"]

    private struct Configuration: Decodable {
        var exclude: [String]?
        var tests: [String]?
    }

    private static func readConfiguration(in root: String) -> (exclude: [Glob], tests: [Glob], problem: String?) {
        let path = "\(root)/\(configurationFileName)"
        guard let data = FileManager.default.contents(atPath: path) else {
            return ([], [], nil)
        }
        let configuration: Configuration
        do {
            configuration = try JSONDecoder().decode(Configuration.self, from: data)
        } catch {
            return ([], [], "\(configurationFileName) is not valid JSON of the form {\"exclude\": [...], \"tests\": [...]}: \(error.localizedDescription)")
        }
        let patterns = (configuration.exclude ?? []) + (configuration.tests ?? [])
        let invalid = patterns.filter { Glob($0) == nil }
        guard invalid.isEmpty else {
            return ([], [], "\(configurationFileName) has invalid pattern(s): \(invalid.joined(separator: ", ")).")
        }
        return (
            (configuration.exclude ?? []).compactMap(Glob.init),
            (configuration.tests ?? []).compactMap(Glob.init),
            nil
        )
    }
}
