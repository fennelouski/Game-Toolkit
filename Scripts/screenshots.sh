#!/bin/bash
# Captures App Store screenshots for every supported platform.
#
#   ./Scripts/screenshots.sh            # all platforms
#   ./Scripts/screenshots.sh ios        # iPhone + iPad only
#
# Screenshots land in Screenshots/<platform>/. Demo data comes from the DEBUG-only
# -screenshotMode launch argument, so runs are reproducible.
set -uo pipefail

PROJECT="Game Toolkit.xcodeproj"
SCHEME="Game Toolkit"
BUNDLE_ID="com.nathanfennel.Game-Toolkit"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Screenshots"
cd "$ROOT" || exit 1

# tab index -> file name
TABS=("0:1-dice" "1:2-timer" "2:3-scores" "4:5-settings")

build_sim() {   # $1 = sdk, $2 = destination
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -sdk "$1" \
        -destination "$2" -configuration Debug \
        CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO build >/dev/null 2>&1
}

app_path() {    # $1 = build dir suffix (e.g. Debug-iphonesimulator)
    echo "$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
        | awk -F' = ' '/ BUILD_DIR /{print $2; exit}')/$1/$SCHEME.app"
}

shoot_simulator() {  # $1 = device udid, $2 = output subdir, $3 = app path
    local udid="$1" dir="$2" app="$3"
    mkdir -p "$OUT/$dir"
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
    # Apple's canonical marketing status bar: 9:41, full signal, full battery.
    xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged \
        --batteryLevel 100 --cellularMode active --cellularBars 4 \
        --wifiMode active --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1
    xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1
    xcrun simctl install "$udid" "$app" >/dev/null 2>&1 || { echo "  install failed"; return 1; }
    for entry in "${TABS[@]}"; do
        local idx="${entry%%:*}" name="${entry##*:}"
        xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1
        sleep 1
        xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshotMode -ui.selectedTab "$idx" >/dev/null 2>&1
        sleep 4
        xcrun simctl io "$udid" screenshot "$OUT/$dir/$name.png" >/dev/null 2>&1 \
            && echo "  $dir/$name.png"
    done
    # Chart view of the scorecard.
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1
    sleep 1
    xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshotMode -ui.selectedTab 2 -showChart >/dev/null 2>&1
    sleep 4
    xcrun simctl io "$udid" screenshot "$OUT/$dir/4-chart.png" >/dev/null 2>&1 \
        && echo "  $dir/4-chart.png"
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1
}

WHICH="${1:-all}"

if [[ "$WHICH" == "all" || "$WHICH" == "ios" ]]; then
    echo "==> iOS"
    build_sim iphonesimulator 'platform=iOS Simulator,name=iPhone 17 Pro Max'
    APP="$(app_path Debug-iphonesimulator)"
    IPHONE=$(xcrun simctl list devices available | grep "iPhone 17 Pro Max" | grep -oE "[0-9A-F-]{36}" | head -1)
    IPAD=$(xcrun simctl list devices available | grep "iPad Pro 13-inch" | grep -oE "[0-9A-F-]{36}" | head -1)
    [ -n "$IPHONE" ] && { echo " iPhone 17 Pro Max"; xcrun simctl boot "$IPHONE" >/dev/null 2>&1; shoot_simulator "$IPHONE" iphone-6.9 "$APP"; }
    [ -n "$IPAD" ] && { echo " iPad Pro 13-inch"; xcrun simctl boot "$IPAD" >/dev/null 2>&1; shoot_simulator "$IPAD" ipad-13 "$APP"; }
fi

if [[ "$WHICH" == "all" || "$WHICH" == "visionos" ]]; then
    echo "==> visionOS"
    VISION=$(xcrun simctl list devices available | grep -i "Apple Vision Pro" | grep -oE "[0-9A-F-]{36}" | head -1)
    if [ -n "$VISION" ]; then
        build_sim xrsimulator 'platform=visionOS Simulator,name=Apple Vision Pro'
        xcrun simctl boot "$VISION" >/dev/null 2>&1
        shoot_simulator "$VISION" visionos "$(app_path Debug-xrsimulator)"
    else
        echo "  no visionOS simulator installed - skipping"
    fi
fi

if [[ "$WHICH" == "all" || "$WHICH" == "mac" ]]; then
    echo "==> Mac Catalyst"
    "$ROOT/Scripts/screenshot-mac.sh"
fi

echo "Done. See $OUT"
