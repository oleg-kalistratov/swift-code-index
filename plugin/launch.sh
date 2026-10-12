#!/bin/bash
# Starts the MCP server for Claude Code in the project folder Claude Code passes
# as the first argument, inside a macOS sandbox (sandbox.sb) with no network
# access and writes limited to the server's cache.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/common.sh"

if [[ -n "${1:-}" && -d "$1" ]]; then
  cd "$1"
fi

if [[ ! -x "$server_binary" ]]; then
  # Claude Code waits 30 s for a server to start, and a first build takes about
  # two minutes: start it (or join the SessionStart one) and wait what we can.
  nohup "$here/build.sh" >/dev/null 2>&1 &
  for _ in $(seq 25); do
    [[ -x "$server_binary" ]] && break
    sleep 1
  done
fi
if [[ ! -x "$server_binary" ]]; then
  echo "swift-code-index: building the server for the first time, which takes about two minutes (log: $build_log). Run /mcp and reconnect swift-code-index when it is done." >&2
  exit 1
fi

cache_dir="$HOME/Library/Caches/index-store-mcp"
mkdir -p "$cache_dir"
exec /usr/bin/sandbox-exec -f "$here/sandbox.sb" \
  -D CACHE_DIR="$cache_dir" \
  -D TMP_DIR="$(getconf DARWIN_USER_TEMP_DIR)" \
  "$server_binary"
