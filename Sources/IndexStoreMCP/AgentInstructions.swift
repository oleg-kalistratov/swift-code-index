/// Snippet printed by `--print-agent-instructions`, meant to be pasted into a
/// project's CLAUDE.md / AGENTS.md so agents prefer the index over grep.
enum AgentInstructions {
    static let text = """
    ## Swift code navigation (swift-code-index)

    If the swift-code-index tools are available in this session (an MCP server named
    swift-code-index, or tools such as `loadIndex`, `searchSymbol` and `getOccurrences`),
    use them first for Swift and Objective-C symbols: where a type, method or property is
    defined, who calls or uses it, which types implement a protocol, what overrides a
    method, and what is in a large file. This holds inside any workflow or skill that is
    driving the task. Lookups are exact, so there are no false matches from comments,
    strings or similarly named symbols. If the tools are not available, or the index
    reports that the project has not been built, search as usual with grep and file reads.

    Workflow:
    1. Call `loadIndex` once per session. With no arguments it loads the project in the
       current folder; pass workspacePath for another .xcworkspace, .xcodeproj or package.
    2. `searchSymbol` (exact name) or `searchSymbolPattern` (partial name) to get a USR.
    3. `getOccurrences` with the USR to find usages and callers; `findImplementations` to find
       conforming types and implementing members; `relatedOccurrences` for members and extensions.
    4. `symbolAtPosition` to get the USR at a file position; `symbolsInFile` for a file outline.
    5. `refreshIndex` after a build.

    Results cover the project's own code; pass includeDependencies to search Swift packages
    and Pods as well. Rows from test code are marked "test": true; pass excludeTests to drop
    them. The index is as fresh as the last build: files edited since then are left out unless
    you pass includeStale. Use grep for non-symbol text such as strings, comments and config files.
    """
}
