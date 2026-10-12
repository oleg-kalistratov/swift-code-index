---
name: code-index
description: Use for questions about Swift or Objective-C code in an Xcode project or Swift package — where a type, method or property is defined, who calls or uses it, which types implement a protocol or which members implement a requirement, what a change would break, or what is in a large file. Answers come from Xcode's own index through the swift-code-index MCP tools, exactly and without reading whole files; prefer them over grep for symbols.
---

# Navigating Swift code with the Xcode index

The swift-code-index tools answer from the index Xcode writes while it builds, so a symbol lookup is exact: no matches from comments, strings or other symbols with the same name.

## Workflow

1. `loadIndex` once per session, with no arguments: it loads the project in the current folder (its `.xcworkspace`, else `.xcodeproj`, else Swift package). If it says no DerivedData was found, the project has not been built yet — ask the user to build it in Xcode once.
2. `searchSymbol` with an exact name (`MyService`, `fetch(id:)`) or `searchSymbolPattern` with part of one, to get a USR.
3. With the USR:
   - `getOccurrences` — every use; `roles: ["call"]` for callers only;
   - `findImplementations` — types conforming to a protocol or subclassing a class, or members implementing a requirement or overriding a method; run it before changing a protocol;
   - `relatedOccurrences` — a type's members, the protocols it builds on, its extensions.
4. `symbolsInFile` for the outline of a large file before reading it, then read only the part you need. `symbolAtPosition` gives the USR of a name at a line and column.
5. `refreshIndex` after the project was rebuilt.

## Reading the results

- Results cover the project's own code. Add `includeDependencies: true` to search Swift packages, Pods and Carthage too.
- Rows from test code carry `"test": true`; `excludeTests: true` drops them. Test targets are in the index only after the tests were built.
- A note at the end says how many results were left out and why (system frameworks, dependencies, test code, or stale — edited since the last build).
- The index knows symbols, not text: use grep for strings, comments and configuration files.
