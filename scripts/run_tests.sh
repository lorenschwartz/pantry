#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_tests.sh — Build and run all Pantry tests (unit + UI)
#
# Usage:
#   ./scripts/run_tests.sh              # auto-detect booted simulator
#   ./scripts/run_tests.sh <UDID>       # run on a specific simulator UDID
#
# Requirements:
#   • Xcode command-line tools installed  (xcode-select --install)
#   • At least one iOS Simulator available (see: xcrun simctl list devices)
#
# Output:
#   • Raw xcodebuild output → /tmp/pantry_test_output.txt
#   • Structured result bundle → TestResults.xcresult  (double-click to open)
#
# Notes:
#   This script is also installed as .git/hooks/pre-push via a symlink.
#   Two quirks are handled for that use-case:
#     1. Symlink resolution: $0 points to .git/hooks/pre-push, not the real
#        script, so we resolve the real path before computing PROJECT_DIR.
#     2. Git passes <remote-name> <remote-url> as $1/$2 to pre-push hooks;
#        we only treat $1 as a simulator UDID when it matches UUID format.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ─── 0. Resolve the real script location (survives symlinks) ─────────────────
# When invoked as .git/hooks/pre-push -> ../../scripts/run_tests.sh,
# $0 is the symlink path (.git/hooks/pre-push), not the target.
# Follow the chain of symlinks to reach the actual file.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    LINK_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$LINK_DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

SCHEME="pantry"
PROJECT="$PROJECT_DIR/pantry.xcodeproj"
RESULTS="$PROJECT_DIR/TestResults.xcresult"
LOG="/tmp/pantry_test_output.txt"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪  Pantry — Test Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── 1. Resolve the simulator UDID ───────────────────────────────────────────
# Only treat $1 as a simulator UDID if it matches the standard UUID format.
# When invoked as a git pre-push hook, git passes:
#   $1 = remote name (e.g. "origin")
#   $2 = remote URL
# — neither of which is a valid UDID.
UDID_RE='^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'

if [[ "${1:-}" =~ $UDID_RE ]]; then
  SIMULATOR_UDID="$1"
  echo "📱  Using provided simulator: $SIMULATOR_UDID"
else
  # Look for the first currently-booted iOS simulator.
  SIMULATOR_UDID=$(
    xcrun simctl list devices booted --json 2>/dev/null \
    | python3 - <<'PYEOF'
import sys, json
data = json.load(sys.stdin)
for devs in data.get("devices", {}).values():
    for d in devs:
        if d.get("state") == "Booted" and d.get("isAvailable", True):
            print(d["udid"]); exit()
print("")
PYEOF
  )

  if [ -z "$SIMULATOR_UDID" ]; then
    # No booted simulator — try to find and boot an iPhone 16.
    echo "⚠️   No booted simulator found. Looking for an available iPhone 16…"
    SIMULATOR_UDID=$(
      xcrun simctl list devices available --json 2>/dev/null \
      | python3 - <<'PYEOF'
import sys, json
data = json.load(sys.stdin)
# Prefer newer runtimes first.
runtimes = sorted(data.get("devices", {}).keys(), reverse=True)
for runtime in runtimes:
    if "iOS" not in runtime:
        continue
    for d in data["devices"][runtime]:
        if d.get("isAvailable") and "iPhone 16" in d.get("name", ""):
            print(d["udid"]); exit()
# Fallback: any available iPhone.
for runtime in runtimes:
    if "iOS" not in runtime:
        continue
    for d in data["devices"][runtime]:
        if d.get("isAvailable") and "iPhone" in d.get("name", ""):
            print(d["udid"]); exit()
print("")
PYEOF
    )

    if [ -z "$SIMULATOR_UDID" ]; then
      echo "❌  No iOS simulator available."
      echo "    Open Xcode → Window → Devices and Simulators and create one first."
      exit 1
    fi

    echo "🔄  Booting simulator $SIMULATOR_UDID …"
    xcrun simctl boot "$SIMULATOR_UDID"
    # Give the system a few seconds to finish booting.
    sleep 5
  fi

  echo "📱  Using simulator: $SIMULATOR_UDID"
fi

# ─── 2. Run xcodebuild test ───────────────────────────────────────────────────

echo "📂  Project : $PROJECT"
echo "🎯  Scheme  : $SCHEME"
echo ""

# Remove any stale result bundle so Xcode doesn't merge with an old run.
rm -rf "$RESULTS"

set +e   # Don't exit on xcodebuild failure — we inspect the output instead.
xcodebuild test \
  -project     "$PROJECT"  \
  -scheme      "$SCHEME"   \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -resultBundlePath "$RESULTS" \
  2>&1 | tee "$LOG"
XCODE_EXIT=${PIPESTATUS[0]}
set -e

# ─── 3. Report ───────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Use -F (fixed string) to avoid treating "**" as a regex repetition operator.
if grep -qF "** TEST SUCCEEDED **" "$LOG"; then
  echo "  ✅  All tests passed."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "  ❌  Tests failed."
  echo ""
  echo "  Full output : $LOG"
  echo "  Result bundle (double-click to open in Xcode):"
  echo "              : $RESULTS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit "${XCODE_EXIT:-1}"
fi
