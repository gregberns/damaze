#!/bin/bash
# Fast, reliable test runner for polecats and CI.
# Handles simulator boot, output filtering, and timeout.
#
# Usage:
#   scripts/test.sh           # Run all tests
#   scripts/test.sh build     # Build only (no tests)
#   scripts/test.sh quick     # Skip xcodegen, assume project is current

set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME="DamazeTests"
SIM_NAME="iPhone 16"
TIMEOUT=300  # 5 minute hard timeout

# --- Ensure simulator is booted ---
SIM_UDID=$(xcrun simctl list devices available -j \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == '$SIM_NAME' and d['state'] == 'Booted':
            print(d['udid']); sys.exit(0)
# No booted sim found, pick first available
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == '$SIM_NAME':
            print(d['udid']); sys.exit(0)
sys.exit(1)
" 2>/dev/null) || { echo "FAIL: No '$SIM_NAME' simulator found"; exit 1; }

SIM_STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIM_UDID':
            print(d['state']); sys.exit(0)
" 2>/dev/null)

if [ "$SIM_STATE" != "Booted" ]; then
    echo "Booting simulator $SIM_NAME..."
    xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
    # Wait for boot (max 30s)
    for i in {1..30}; do
        STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIM_UDID':
            print(d['state']); sys.exit(0)
" 2>/dev/null)
        [ "$STATE" = "Booted" ] && break
        sleep 1
    done
fi

DEST="platform=iOS Simulator,id=$SIM_UDID"

# --- Regenerate project if needed ---
if [ "${1:-}" != "quick" ]; then
    if command -v xcodegen &>/dev/null; then
        xcodegen generate --quiet 2>/dev/null || xcodegen generate 2>/dev/null || true
    fi
fi

# --- Determine action ---
ACTION="test"
[ "${1:-}" = "build" ] && ACTION="build"

# --- Run xcodebuild with timeout ---
if command -v xcsift &>/dev/null; then
    timeout "$TIMEOUT" xcodebuild \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination "$DEST" \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
        "$ACTION" 2>&1 | xcsift
    EXIT=$?
else
    timeout "$TIMEOUT" xcodebuild \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination "$DEST" \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
        "$ACTION" 2>&1 | tail -30
    EXIT=$?
fi

exit $EXIT
