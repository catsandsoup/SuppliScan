#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/SuppliScan/SuppliScan.xcodeproj"
SCHEME="SuppliScan"
BUNDLE_ID="montygiovenco.SuppliScan"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro Max}"
DERIVED_DATA="${TMPDIR:-/tmp}/SuppliScanAppStoreScreenshotsDerivedData"
RESULT_BUNDLE="$ROOT/Marketing/AppStore/Screenshots/AppStoreScreenshots.xcresult"
RAW_OUTPUT="$ROOT/Marketing/AppStore/Screenshots/raw/6.9-inch"
FRAMED_OUTPUT="$ROOT/Marketing/AppStore/Screenshots/framed/6.9-inch"
SENTINEL="$ROOT/.asc/capture-screenshots.enabled"

cleanup() {
  rm -f "$SENTINEL"
}
trap cleanup EXIT

UDID="$(xcrun simctl list devices available -j | jq -r --arg name "$SIM_NAME" '.devices[][] | select(.name == $name) | .udid' | head -n 1)"

if [[ -z "$UDID" ]]; then
  echo "Simulator not found: $SIM_NAME" >&2
  exit 1
fi

rm -rf "$RAW_OUTPUT" "$FRAMED_OUTPUT" "$RESULT_BUNDLE" "$DERIVED_DATA"
mkdir -p "$RAW_OUTPUT"
touch "$SENTINEL"

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

APP_STORE_SCREENSHOT_DIR="$RAW_OUTPUT" \
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -parallel-testing-enabled NO \
  -only-testing:SuppliScanUITests/SuppliScanUITests/testAppStoreScreenshotJourney

python3 "$ROOT/Tools/build_app_store_promos.py"

echo "Raw screenshots: $RAW_OUTPUT"
echo "Framed screenshots: $ROOT/Marketing/AppStore/Screenshots/framed/6.9-inch"
