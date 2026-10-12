# Shared by build.sh and launch.sh: where the Claude Code plugin keeps the server
# it builds. Sourced, not executed.

plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
data_dir="${CLAUDE_PLUGIN_DATA:-$HOME/Library/Application Support/swift-code-index}"

# A binary is reused only for the exact sources it was built from, so a plugin
# update or a local edit always gets a fresh build.
source_stamp="$(
  cd "$plugin_root" &&
    find Package.swift Package.resolved Sources -type f -print0 |
    LC_ALL=C sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-16
)"
server_binary="$data_dir/bin/index-store-mcp-$source_stamp"
build_log="$data_dir/build.log"
