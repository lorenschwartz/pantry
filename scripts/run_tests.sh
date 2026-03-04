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
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCHEME="pantry"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$PROJECT_DIR/pantry.xcodeproj"
RESULTS="$PROJECT_DIR/TestResults.xcresult"
LOG="/tmp/pantry_test_output.txt"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪  Pantry — Test Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── 1. Resolve the simulator UDID ───────────────────────────────────────────

if [ "${1:-}" != "" ]; then
  # Caller passed an explicit UDID.
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
if grep -q "** TEST SUCCEEDED **" "$LOG"; then
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
