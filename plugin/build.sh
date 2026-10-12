#!/bin/bash
# Builds the MCP server from this plugin's own sources into the plugin's data
# folder, unless a binary for these exact sources is already there. Runs from the
# SessionStart hook and, on a first launch, from launch.sh; a lock folder keeps
# the two from building at once.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ -x "$server_binary" ]] && exit 0
mkdir -p "$data_dir/bin"

lock="$data_dir/build.lock"
# A build takes a few minutes; a lock older than 20 is left by a killed build.
if [[ -d "$lock" && -n "$(find "$lock" -maxdepth 0 -mmin +20)" ]]; then
  rmdir "$lock"
fi
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock"' EXIT

build=(swift build -c release --package-path "$plugin_root" --scratch-path "$data_dir/build")
{
  echo "$(date '+%Y-%m-%d %H:%M:%S') building $source_stamp from $plugin_root"
  "${build[@]}"
} >"$build_log" 2>&1
bin_path="$("${build[@]}" --show-bin-path)"

cp "$bin_path/index-store-mcp" "$server_binary.partial"
mv "$server_binary.partial" "$server_binary"
find "$data_dir/bin" -name 'index-store-mcp-*' ! -name "$(basename "$server_binary")" -delete
echo "$(date '+%Y-%m-%d %H:%M:%S') built $server_binary" >>"$build_log"
