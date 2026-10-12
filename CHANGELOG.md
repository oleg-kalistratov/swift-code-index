# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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

First release, distributed as a prebuilt Apple silicon binary through Homebrew.

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

[0.1.0]: https://github.com/hrdkp/swift-index-store-mcp/releases/tag/v0.1.0
