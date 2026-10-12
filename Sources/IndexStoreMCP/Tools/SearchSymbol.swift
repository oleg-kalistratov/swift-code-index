import MCP
@preconcurrency import IndexStoreDB
import Foundation

func handleSearchSymbol(_ args: [String: Value], indexStore: IndexStore) async throws -> CallTool.Result {
    guard let context = await indexStore.indexContext else {
        return .failure("No index loaded. Call loadIndex first.")
    }
    let database = context.database
    let scope = ProjectScope(workspacePath: context.workspacePath)
    
    guard let name = args["name"]?.stringValue else {
        return .failure("Missing required argument: name")
    }
    
    let includeSystem = args["includeSystem"]?.boolValue ?? false
    let includeStale = args["includeStale"]?.boolValue ?? false
    let includeDependencies = args["includeDependencies"]?.boolValue ?? false
    
    var all = database.canonicalOccurrences(ofName: name).uniqued()
    var nonSystem = all.filter { includeSystem || !$0.location.isSystem }
    var inProject = nonSystem.filter { includeDependencies || scope.contains($0.location.path) }
    var results = inProject.filter { includeStale || !$0.isStale(in: database) }
    
    // Exact match failed (or was entirely stale) — try prefix match to handle
    // bare method names (e.g. "reserveLoading" → "reserveLoading(workspacePath:)").
    // An exact match that exists only in dependencies is still an answer: report
    // it as excluded rather than widening the search past it.
    if results.isEmpty && inProject.count == nonSystem.count {
        all = database.canonicalOccurrences(
            containing: name,
            anchorStart: true,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        ).uniqued()
        nonSystem = all.filter { includeSystem || !$0.location.isSystem }
        inProject = nonSystem.filter { includeDependencies || scope.contains($0.location.path) }
        results = inProject.filter { includeStale || !$0.isStale(in: database) }
        
        if results.isEmpty && inProject.count == nonSystem.count {
            return .success("No match found for '\(name)'. Try searchSymbolPattern with a partial name.")
        }
    }
    
    let items: [[String: String]] = results.map { $0.toCanonicalDict() }
    let output = try formatOccurrenceJSON(items, systemCount: all.count - nonSystem.count, dependencyCount: nonSystem.count - inProject.count, staleCount: inProject.count - results.count)
    return .success(output)
}
