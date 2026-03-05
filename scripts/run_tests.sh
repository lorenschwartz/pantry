#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_tests.sh — Build and run all Pantry tests (unit + UI)
#
# Usage:
#   ./scripts/run_tests.sh              # auto-detect (or boot) a simulator
#   ./scripts/run_tests.sh <UDID>       # use a specific simulator UDID
#
# When invoked as a git pre-push hook the script runs tests only if a
# simulator is already booted.  With no booted simulator it exits 0 so
# day-to-day pushes are never accidentally blocked.
# GitHub Actions (ci.yml) is the authoritative CI gate.
#
# Output:
#   • Raw xcodebuild output → /tmp/pantry_test_output.txt
#   • Structured result bundle → TestResults.xcresult
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ─── 0. Resolve real script location (follows symlinks) ──────────────────────
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

# ─── 1. Resolve simulator UDID ───────────────────────────────────────────────
#
# Only accept $1 as a UDID when it matches the UUID format.
# git pre-push passes $1=remote-name, $2=remote-url — ignore those.

UDID_RE='^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'

if [[ "${1:-}" =~ $UDID_RE ]]; then
  # Explicit UDID from CI (GitHub Actions passes this directly).
  SIMULATOR_UDID="$1"
  echo "📱  Using provided simulator: $SIMULATOR_UDID"
else
  # ── Auto-detect a booted simulator ───────────────────────────────────────
  # Use python3 -c so the script is a CLI arg and stdin remains free for
  # the pipe data.  The || true prevents set -e/-o pipefail from aborting
  # when simctl exits non-zero (e.g. when the daemon isn't running).
  SIMULATOR_UDID=$(
    xcrun simctl list devices booted --json 2>/dev/null \
    | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    for devs in data.get('devices', {}).values():
        for d in devs:
            if d.get('state') == 'Booted' and d.get('isAvailable', True):
                print(d['udid']); exit()
except Exception:
    pass
" 2>/dev/null
  ) || SIMULATOR_UDID=""   # absorb any pipeline / set -e exit

  if [ -z "$SIMULATOR_UDID" ]; then
    # No booted simulator.  If we're running as a git hook (parent is git),
    # skip gracefully so the push is never blocked by a missing simulator.
    PARENT_CMD="$(ps -o comm= -p "$PPID" 2>/dev/null || true)"
    if [[ "$PARENT_CMD" == *"git"* ]] || [[ "$PARENT_CMD" == *"hooks"* ]]; then
      echo "⚠️   No booted simulator — skipping local tests."
      echo "    GitHub Actions will run the full suite on push."
      echo "    To run tests locally: open Simulator.app first, then push again."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    fi

    # Direct invocation: try to find and boot a simulator.
    echo "⚠️   No booted simulator. Looking for an available iPhone 16…"
    SIMULATOR_UDID=$(
      xcrun simctl list devices available --json 2>/dev/null \
      | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    runtimes = sorted(data.get('devices', {}).keys(), reverse=True)
    for rt in runtimes:
        if 'iOS' not in rt: continue
        for d in data['devices'][rt]:
            if d.get('isAvailable') and 'iPhone 16' in d.get('name', ''):
                print(d['udid']); exit()
    for rt in runtimes:
        if 'iOS' not in rt: continue
        for d in data['devices'][rt]:
            if d.get('isAvailable') and 'iPhone' in d.get('name', ''):
                print(d['udid']); exit()
except Exception:
    pass
" 2>/dev/null
    ) || SIMULATOR_UDID=""

    if [ -z "$SIMULATOR_UDID" ]; then
      echo "❌  No iOS simulator available."
      echo "    Open Xcode → Window → Devices and Simulators and create one first."
      exit 1
    fi

    echo "🔄  Booting $SIMULATOR_UDID …"
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
    sleep 5
  fi

  echo "📱  Using simulator: $SIMULATOR_UDID"
fi

# ─── 2. Run tests ─────────────────────────────────────────────────────────────

echo "📂  Project : $PROJECT"
echo "🎯  Scheme  : $SCHEME"
echo ""

rm -rf "$RESULTS"

set +e
xcodebuild test \
  -project     "$PROJECT" \
  -scheme      "$SCHEME"  \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -resultBundlePath "$RESULTS" \
  2>&1 | tee "$LOG"
XCODE_EXIT=${PIPESTATUS[0]}
set -e

# ─── 3. Report ────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if grep -qF "** TEST SUCCEEDED **" "$LOG"; then
  echo "  ✅  All tests passed."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "  ❌  Tests failed."
  echo ""
  echo "  Full output : $LOG"
  echo "  Result bundle: open $RESULTS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit "${XCODE_EXIT:-1}"
fi
