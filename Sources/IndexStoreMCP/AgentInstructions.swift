/// Snippet printed by `--print-agent-instructions`, meant to be pasted into a
/// project's CLAUDE.md / AGENTS.md so agents prefer the index over grep.
enum AgentInstructions {
    static let text = """
    ## Xcode Navigation (index-store-mcp)

    Prefer the index-store-mcp tools over grep/file reads for Swift and Objective-C
    symbol navigation: finding definitions, references and callers, protocol
    conformances, overrides, extensions, and file outlines. Lookups are exact (by USR),
    so there are no false matches from comments, strings or similarly named symbols.

    Workflow:
    1. Call `loadIndex` once per session. With no arguments it loads the project in the
       current folder; pass workspacePath for another .xcworkspace, .xcodeproj or package.
    2. `searchSymbol` (exact name) or `searchSymbolPattern` (partial name) to get a USR.
    3. `getOccurrences` with the USR to find usages and callers; `findImplementations` to find
       conforming types and implementing members; `relatedOccurrences` for members and extensions.
    4. `symbolAtPosition` to get the USR at a file position; `symbolsInFile` for a file outline.
    5. `refreshIndex` after a build.

    Results cover the project's own code; pass includeDependencies to search Swift packages
    and Pods as well. Fall back to grep for non-symbol text such as strings, comments, and
    config files.
    """
}
