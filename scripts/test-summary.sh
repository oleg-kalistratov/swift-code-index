#!/bin/bash
# Turn `swift test` console output into a short Markdown summary for the CI job
# page: the final count line and, when something failed, which tests did.
# Usage: scripts/test-summary.sh test-output.log >>"$GITHUB_STEP_SUMMARY"
set -euo pipefail

log="${1:?usage: test-summary.sh test-output.log}"
# Swift Testing prefixes lines with SF Symbols glyphs; compare bytes, not characters.
export LC_ALL=C
strip() { sed -E 's/^[^A-Za-z]*//'; }

echo "### Tests"
echo
result="$(grep -E 'Test run with [0-9]+ tests? ' "$log" 2>/dev/null | tail -1 | strip || true)"
echo "${result:-No test result found: the build or the test run stopped early. See the Run tests step.}"

failed="$(grep -E '^[^A-Za-z]*Test [A-Za-z0-9_]+\([^)]*\) (failed|recorded an issue)' "$log" 2>/dev/null | strip | sed -E -e 's/^Test //' -e 's/ (failed|recorded an issue).*//' | sort -u || true)"
if [[ -n "$failed" ]]; then
  echo
  echo "**Failed:**"
  echo
  while IFS= read -r test; do
    echo "- \`$test\`"
  done <<<"$failed"
fi
