import Foundation

/// Tells the project's own source files apart from its dependencies' sources,
/// which the index also holds once they have been built.
///
/// The root is the folder holding the .xcworkspace or .xcodeproj, or the package
/// directory itself. Swift packages resolved by Xcode live in DerivedData, outside
/// the root; CocoaPods, Carthage and SwiftPM checkouts sit inside it, so those
/// folders are excluded by name.
struct ProjectScope {
    let root: String

    init(workspacePath: String) {
        let url = URL(fileURLWithPath: workspacePath).standardizedFileURL
        let isContainer = url.pathExtension == "xcworkspace" || url.pathExtension == "xcodeproj"
        root = isContainer ? url.deletingLastPathComponent().path : url.path
    }

    func contains(_ path: String) -> Bool {
        guard path.hasPrefix(root + "/") else { return false }
        let relative = path.dropFirst(root.count + 1)
        return !Self.vendoredFolders.contains { relative.hasPrefix($0) }
    }

    private static let vendoredFolders = ["Pods/", "Carthage/", ".build/"]
}
