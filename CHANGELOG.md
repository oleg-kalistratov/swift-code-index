# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- `--print-agent-instructions` now tells the agent to use the index only when the
  swift-code-index tools are available in the session, and to search as usual
  otherwise, so the snippet can go into a project's shared `CLAUDE.md` or
  `AGENTS.md` even when not everyone on the team installs the plugin. It also
  says the index applies inside other workflows and skills: on a large app the
  agent ignored the plugin's own skill once a team workflow took over the task.

## [0.2.0] - 2026-10-12

First release as swift-code-index, a fork of hrdkp/swift-index-store-mcp.
Installed as a Claude Code plugin from this repository; the server binary
keeps its name, `index-store-mcp`.

### Added
- Claude Code plugin in the repository itself, which is also its own
  marketplace: `/plugin marketplace add oleg-kalistratov/swift-code-index`,
  then `/plugin install swift-code-index@swift-code-index`. A SessionStart hook
  builds the server from the plugin's sources into the plugin's data folder
  (about a minute or two, once per plugin version); the server starts in the
  project folder, so `loadIndex` needs no path; a `code-index` skill tells the
  agent when to use the index.
- The plugin runs the server inside a macOS sandbox (`plugin/sandbox.sb`): no
  network access, writes only to its index cache and temporary files. The MCP
  SDK links networking code the server does not use.
- Results from test code are marked `"test": true`, and every search tool takes
  `excludeTests`. Test code is a `…Tests` module or a file in a `…Tests`,
  `Mocks`, `Fakes`, `Stubs`, `TestSupport` or `TestHelpers` folder.
- Optional `.swift-code-index.json` in the project root with `exclude` and
  `tests` path patterns (`.gitignore`-style). `loadIndex` reports the file, or
  the problem with it and falls back to the defaults.
- `loadIndex` works without `workspacePath`: it loads the project in the
  server's working directory, preferring an `.xcworkspace`, then an
  `.xcodeproj`, then a Swift package, and picks the first one Xcode has built.
- `includeDependencies` on `searchSymbol`, `searchSymbolPattern`,
  `getOccurrences`, `relatedOccurrences` and `findImplementations`. By default
  results come from the project's own code only, with a note counting what was
  left out in Swift packages, Pods and Carthage checkouts. On a large app 85 of
  192 fuzzy matches came from SDK checkouts.
- `findImplementations`: given a protocol or class, lists every conforming or
  inheriting type (including extensions that add the conformance); given a
  protocol requirement or overridable method, lists every implementing member.
  `relatedOccurrences` asked about a protocol returns the protocol's own members
  and bases, not its conformers.

### Changed
- `symbolsInFile` leaves out parameters and compiler-synthesized members, and
  omits USRs and roles unless asked (`includeUSR`, an explicit `roles` filter).
  On a 4,400-line file the outline went from 172,685 to 35,338 characters.
- `searchSymbolPattern` returns at most `limit` matches (default 50), shortest
  names first, and notes how many were left out. A short pattern on a large app
  went from 120,453 to 21,077 characters.

## [0.1.0] - 2026-10-05

First release of the upstream project, hrdkp/swift-index-store-mcp,
distributed as a prebuilt Apple silicon binary through its Homebrew tap.

### Added
- MCP server over stdio with eight tools: `loadIndex`, `searchSymbol`,
  `searchSymbolPattern`, `symbolAtPosition`, `getOccurrences`,
  `relatedOccurrences`, `symbolsInFile`, `refreshIndex`.
- `--version`, `--help`, and `--print-agent-instructions` (a snippet for
  `CLAUDE.md` / `AGENTS.md` that tells agents to prefer the index over grep).
- `loadIndex` reports which `libIndexStore.dylib` it loaded, and explains how to
  select a newer Xcode when the selected one is too old.

### Requirements
- Apple silicon Mac with Xcode 16 or later selected (`xcode-select` or
  `DEVELOPER_DIR`).

[0.2.0]: https://github.com/oleg-kalistratov/swift-code-index/releases/tag/v0.2.0
[0.1.0]: https://github.com/hrdkp/swift-index-store-mcp/releases/tag/v0.1.0
