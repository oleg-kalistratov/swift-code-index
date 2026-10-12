import MCP
@preconcurrency import IndexStoreDB
import Foundation

func handleSearchSymbolPattern(_ args: [String: Value], indexStore: IndexStore) async throws -> CallTool.Result {
    guard let context = await indexStore.indexContext else {
        return .failure("No index loaded. Call loadIndex first.")
    }
    let database = context.database
    let scope = ProjectScope(workspacePath: context.workspacePath)
    
    guard let pattern = args["pattern"]?.stringValue else {
        return .failure("Missing required argument: pattern")
    }
    
    let anchorStart   = args["anchorStart"]?.boolValue   ?? false
    let anchorEnd     = args["anchorEnd"]?.boolValue     ?? false
    let subsequence   = args["subsequence"]?.boolValue   ?? true
    let ignoreCase    = args["ignoreCase"]?.boolValue    ?? true
    let includeSystem = args["includeSystem"]?.boolValue ?? false
    let includeStale = args["includeStale"]?.boolValue ?? false
    let includeDependencies = args["includeDependencies"]?.boolValue ?? false
    let limit = max(1, args["limit"]?.intValue ?? 50)
    
    let all = database.canonicalOccurrences(
        containing: pattern,
        anchorStart: anchorStart,
        anchorEnd: anchorEnd,
        subsequence: subsequence,
        ignoreCase: ignoreCase
    ).uniqued()
    let nonSystem = all.filter { includeSystem || !$0.location.isSystem }
    let inProject = nonSystem.filter { includeDependencies || scope.contains($0.location.path) }
    // Shortest names first: with subsequence matching on, the closest match to the
    // pattern is the one with the fewest extra characters.
    let results = inProject
        .filter { includeStale || !$0.isStale(in: database) }
        .sorted { ($0.symbol.name.count, $0.symbol.name, $0.location.path) < ($1.symbol.name.count, $1.symbol.name, $1.location.path) }
    let shown = results.prefix(limit)
    
    let items: [[String: String]] = shown.map { $0.toCanonicalDict() }
    var output = try formatOccurrenceJSON(items, systemCount: all.count - nonSystem.count, dependencyCount: nonSystem.count - inProject.count, staleCount: inProject.count - results.count)
    if shown.count < results.count {
        output += "\n\nNote: showing \(shown.count) of \(results.count) matches, shortest names first. Use a longer pattern, anchorStart/anchorEnd, or a higher limit."
    }
    return .success(output)
}
