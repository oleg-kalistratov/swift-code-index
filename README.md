# swift-code-index

[![Test](https://github.com/oleg-kalistratov/swift-code-index/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/oleg-kalistratov/swift-code-index/actions/workflows/test.yml)
[![License](https://img.shields.io/github/license/oleg-kalistratov/swift-code-index)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Xcode%2016%2B-blue)

Based on [hrdkp/swift-index-store-mcp](https://github.com/hrdkp/swift-index-store-mcp) (MIT). The server binary keeps its original name, `index-store-mcp`.

An MCP server that gives coding agents semantic code navigation for Xcode projects. Instead of relying on `grep` and file reading, agents can look up symbols by name, find definitions and references by USR, trace protocol conformances and overrides, and get structural outlines of files — the same navigation that Xcode provides via Cmd+Click and Find Usages.

Built on Apple's [IndexStoreDB](https://github.com/swiftlang/indexstore-db) library, which reads the index data that Xcode generates during builds.

## When is this useful?

- **Large codebases** where `grep` returns too much noise. Symbol lookup by USR is exact — no false matches from comments, strings, or similarly named symbols.
- **Refactoring** — find all protocol conformances, method overrides, and extensions before changing a type or interface. `findImplementations` lists every conforming type or implementing member in one call; `relatedOccurrences` covers members and extensions.
- **Navigating unfamiliar code** — agents can trace call graphs and jump between definitions and references the same way a developer uses Cmd+Click in Xcode, instead of guessing at file structure.
- **Reducing context window usage** — `symbolsInFile` returns a structural outline (names, kinds, line numbers) without reading the entire source file. For large files this keeps the agent's context focused.
- **Cross-dependency navigation** — the index includes symbols from your project's Swift package dependencies, not just your own source files.

For small projects, `grep` and file reading are usually fast enough. This MCP pays off as project size and complexity grow.

## Requirements

- **Apple silicon Mac**
- **Xcode 16 or later**, selected with `xcode-select` or `DEVELOPER_DIR`. The server loads `libIndexStore.dylib` from the selected Xcode at runtime. Xcode 16 needs macOS 14.5 or later, so that is the effective macOS floor.
- The target project must have been **built in Xcode** at least once, so its index store exists in DerivedData.

## Getting started

### Claude Code plugin

```
/plugin marketplace add oleg-kalistratov/swift-code-index
/plugin install swift-code-index@swift-code-index
```

Or from a shell: `claude plugin marketplace add oleg-kalistratov/swift-code-index`, then `claude plugin install swift-code-index@swift-code-index`.

The plugin builds the server from its own sources on your Mac the first time a session starts, which takes about two minutes and needs the Swift toolchain that comes with Xcode. If you open a session before it finishes, the server reports that it is building; run `/mcp` and reconnect `swift-code-index` a couple of minutes later. Each plugin update rebuilds once, incrementally. The build lives in the plugin's data folder (`~/.claude/plugins/data/…`), with its log in `build.log` there.

The server runs inside a macOS sandbox (`plugin/sandbox.sb`) with no network access and writes limited to its cache in `~/Library/Caches/index-store-mcp`. It works in the project folder Claude Code was started in, so `loadIndex` needs no path. The plugin also ships a `code-index` skill that tells the agent when to use the index instead of `grep`.

**Try it:** build your project in Xcode once, then ask something like "Find every type that conforms to `MyProtocol`."

### Other MCP clients

Build the server from source:

```sh
git clone https://github.com/oleg-kalistratov/swift-code-index.git
cd swift-code-index
swift build -c release
swift build -c release --show-bin-path   # prints the directory containing index-store-mcp
```

Or download the prebuilt Apple silicon binary attached to each [release](https://github.com/oleg-kalistratov/swift-code-index/releases), with its SHA-256 next to it. From a shell, this takes the latest release and checks it:

```sh
gh release download --repo oleg-kalistratov/swift-code-index --pattern 'index-store-mcp-*'
shasum -a 256 -c index-store-mcp-*-arm64-macos.tar.gz.sha256
tar -xzf index-store-mcp-*-arm64-macos.tar.gz
```

The binary is signed ad hoc, not notarized by Apple. Downloaded with `gh` or `curl` it runs as is. Downloaded through a browser, macOS marks it as coming from the internet and refuses to run it; clear the mark once with `xattr -d com.apple.quarantine index-store-mcp`. The Claude Code plugin builds the server on your Mac and is not affected.

Then add it to your client with the absolute path to the binary. GUI apps such as Claude Desktop don't see your shell's `PATH`.

```json
{
  "mcpServers": {
    "swift-code-index": {
      "command": "/absolute/path/to/index-store-mcp"
    }
  }
}
```

To run it sandboxed as the plugin does, point `command` at `/usr/bin/sandbox-exec` with the arguments `launch.sh` passes. To use a different Xcode than the one `xcode-select` points to, add `"env": { "DEVELOPER_DIR": "/Applications/Xcode-16.0.app/Contents/Developer" }`.

Agents often default to `grep` unless told otherwise. From your project's root, append the bundled instructions to its `CLAUDE.md` or `AGENTS.md` once:

```sh
/absolute/path/to/index-store-mcp --print-agent-instructions >> AGENTS.md
```

## How it works

When Xcode builds a project, the compiler writes symbol index data to `DerivedData/<project>/Index.noindex/DataStore`. index-store-mcp reads this data through IndexStoreDB, using the `libIndexStore.dylib` from your selected Xcode, and exposes it over the [Model Context Protocol](https://modelcontextprotocol.io) via stdio.

The server finds DerivedData automatically by checking:
1. The custom DerivedData location from Xcode preferences
2. A `DerivedData` folder next to the workspace (relative mode)
3. The default `~/Library/Developer/Xcode/DerivedData`

It keeps its own lookup database in `~/Library/Caches/index-store-mcp`.

## Project configuration

Results cover the project's own code: files under the folder that holds the `.xcworkspace`, `.xcodeproj` or `Package.swift`, minus `Pods/`, `Carthage/` and `.build/`. Swift packages that Xcode resolves into DerivedData count as dependencies. Every search tool takes `includeDependencies: true` to search them too, and notes how many results it left out.

Results from test code carry `"test": true`, and `excludeTests: true` drops them. Test code is a module named `…Tests`, or a file in a folder named `…Tests`, `Mocks`, `Fakes`, `Stubs`, `TestSupport` or `TestHelpers`.

To adjust either rule, add an optional `.swift-code-index.json` to the project root:

```json
{
  "exclude": ["Generated/**", "*.generated.swift"],
  "tests": ["**/Fixtures/**"]
}
```

Patterns are relative to the project root and follow `.gitignore` rules: `*` stays within a folder, `**` spans folders, a trailing `/` covers a whole folder, and a pattern without a `/` matches a file name anywhere. `loadIndex` reports the file it read, or what is wrong with it; a broken file falls back to the defaults.

The index holds symbol names and locations, never the values of string literals, so a key compiled into the app cannot reach the agent through these tools. Files that are not compiled — `.xcconfig`, `.env`, certificates — are not in the index at all.

## Troubleshooting

- **"No DerivedData found"** — build the project in Xcode (Cmd+B) at least once, then call `loadIndex` again.
- **"libIndexStore … is not compatible"** — the selected Xcode is older than Xcode 16. Run `xcode-select -p` to see which one is selected, then switch with `sudo xcode-select -s /Applications/Xcode.app` or set `DEVELOPER_DIR` in your MCP client config.
- **Results are missing or out of date** — rebuild in Xcode, then call `refreshIndex`. If you build with a newer Xcode than the selected one, select the newer Xcode: the `loadIndex` result shows which `libIndexStore.dylib` is in use.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute, [TESTING.md](TESTING.md) for running the tests, and [CHANGELOG.md](CHANGELOG.md) for release history. To report a security issue, see [SECURITY.md](SECURITY.md).

## License

index-store-mcp is released under the MIT License. See [LICENSE](LICENSE) for details.
