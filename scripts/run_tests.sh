#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_tests.sh — Build and run all Pantry tests (unit + UI)
#
# Usage:
#   ./scripts/run_tests.sh              # auto-detect booted simulator
#   ./scripts/run_tests.sh <UDID>       # run on a specific simulator UDID
#
# When invoked as a git pre-push hook the script runs the full test suite
# only if a simulator is already booted.  If no simulator is available it
# prints a warning and exits 0 (does not block the push) so day-to-day
# pushes are never accidentally blocked by a missing simulator.
# Use GitHub Actions (ci.yml) as the authoritative CI gate.
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

# ─── 0. Resolve the real script location (survives symlinks) ─────────────────
# When invoked as .git/hooks/pre-push -> ../../scripts/run_tests.sh,
# $0 is the symlink path (.git/hooks/pre-push), not the target.
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

# Helper: parse JSON from simctl safely; returns empty string on any error.
simctl_udid() {
  local mode="${1:-booted}"
  python3 -c '
import json, sys

mode = sys.argv[1] if len(sys.argv) > 1 else "booted"
raw = sys.stdin.read().strip()
if not raw:
  sys.exit(0)

try:
  data = json.loads(raw)
except Exception:
  sys.exit(0)

runtimes = sorted(data.get("devices", {}).keys(), reverse=True)
for rt in runtimes:
  if "iOS" not in rt:
    continue
  for d in data.get("devices", {}).get(rt, []):
    if not d.get("isAvailable", True):
      continue
    if mode == "booted" and d.get("state") == "Booted":
      print(d.get("udid", ""))
      sys.exit(0)
    if mode == "iphone16" and "iPhone 16" in d.get("name", ""):
      print(d.get("udid", ""))
      sys.exit(0)
    if mode == "iphone" and "iPhone" in d.get("name", ""):
      print(d.get("udid", ""))
      sys.exit(0)
' "$mode" 2>/dev/null || true
}

# ─── 1. Resolve the simulator UDID ───────────────────────────────────────────
# Only treat $1 as a simulator UDID when it matches the standard UUID format.
# When invoked as a git pre-push hook, git passes:
#   $1 = remote name (e.g. "origin")   $2 = remote URL
UDID_RE='^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'

# Detect probable git hook invocation (git pre-push passes remote + URL args).
PARENT_CMD="$(ps -o comm= -p "$PPID" 2>/dev/null || true)"
IS_GIT_HOOK=false
if [[ "$PARENT_CMD" == *"git"* ]] || [[ "$PARENT_CMD" == *"hooks"* ]]; then
  IS_GIT_HOOK=true
elif [[ -n "${1:-}" && -n "${2:-}" && ! "${1:-}" =~ $UDID_RE ]]; then
  IS_GIT_HOOK=true
fi

if [[ "${1:-}" =~ $UDID_RE ]]; then
  # Explicit UDID passed by CI (GitHub Actions).
  SIMULATOR_UDID="$1"
  echo "📱  Using provided simulator: $SIMULATOR_UDID"
else
  # Auto-detect: prefer a currently-booted device.
  SIMULATOR_UDID=$(xcrun simctl list devices booted --json 2>/dev/null \
    | simctl_udid booted) || SIMULATOR_UDID=""

  if [ -z "$SIMULATOR_UDID" ]; then
    # No booted simulator.  When running as a pre-push hook skip gracefully
    # so the push is never accidentally blocked by a missing simulator.
    # Full CI runs happen on GitHub Actions (ci.yml).
    if [[ "$IS_GIT_HOOK" == true ]]; then
      echo "⚠️   No booted simulator — skipping local tests (CI will run them)."
      echo "    To run tests locally: open Simulator.app, then re-push, or run:"
      echo "    ./scripts/run_tests.sh"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    fi

    # Not a hook invocation — try to find and boot an iPhone 16.
    echo "⚠️   No booted simulator found. Looking for an available iPhone 16…"
    SIMULATOR_UDID=$(xcrun simctl list devices available --json 2>/dev/null \
      | simctl_udid iphone16) || SIMULATOR_UDID=""

    if [ -z "$SIMULATOR_UDID" ]; then
      SIMULATOR_UDID=$(xcrun simctl list devices available --json 2>/dev/null \
        | simctl_udid iphone) || SIMULATOR_UDID=""
    fi

    if [ -z "$SIMULATOR_UDID" ]; then
      echo "❌  No iOS simulator available."
      echo "    Open Xcode → Window → Devices and Simulators and create one first."
      exit 1
    fi

    echo "🔄  Booting simulator $SIMULATOR_UDID …"
    xcrun simctl boot "$SIMULATOR_UDID"
    sleep 5
  fi

  echo "📱  Using simulator: $SIMULATOR_UDID"
fi

# ─── 2. Run xcodebuild test ───────────────────────────────────────────────────

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

# ─── 3. Report ───────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# -F = fixed-string; avoids regex errors from "**" in the xcodebuild output.
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
