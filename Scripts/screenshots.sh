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

# name|tab|extra launch args. Launch args live in NSArgumentDomain, so nothing persists
# between shots. Appearance defaults to light via the status-bar override environment.
SHOTS=(
    "1-dice|0|"
    "2-timer|1|"
    "3-scores|2|"
    "4-chart|2|-showChart"
    "5-settings|4|"
    "6-theme-gaslight|0|-ui.theme gaslight -settings.appearance dark"
    "7-theme-azul|2|-ui.theme azul"
    "8-players|3|-ui.demoGroups -showGallery"
    "9-timer-hourglass|1|-timer.styleID hourglass"
    "10-timer-analog|1|-timer.styleID analog"
    "11-dice-dark|0|-settings.appearance dark"
    "12-theme-wingspan|1|-ui.theme wingspan"
    "13-theme-catan|0|-ui.theme catan"
)

build_sim() {   # $1 = sdk, $2 = destination
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -sdk "$1" \
        -destination "$2" -configuration Debug \
        CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO build >/dev/null 2>&1
}

app_path() {    # $1 = build dir suffix (e.g. Debug-iphonesimulator)
    echo "$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
        | awk -F' = ' '/ BUILD_DIR /{print $2; exit}')/$1/$SCHEME.app"
}

# Capture via a temp file: freshly booted simulators sometimes refuse screenshots
# ("Timeout waiting for screen surfaces"), and sandboxed environments can deny simctl
# direct writes into the repo while plain file moves succeed.
snap() {  # $1 = udid, $2 = output path
    local attempt tmp
    tmp="$(mktemp -t gt-shot).png"
    for attempt in 1 2 3 4; do
        if xcrun simctl io "$1" screenshot "$tmp" >/dev/null 2>&1; then
            mv -f "$tmp" "$2" && return 0
        fi
        sleep 4
    done
    rm -f "$tmp"
    return 1
}

# Other automation on this machine sometimes opens apps on shared simulators, which
# puts a "◀ SomeApp" back-breadcrumb in our status bar. The breadcrumb strip is flat
# background in a clean shot, so any texture there means contamination.
clean_bar() {  # $1 = png path, $2 = device dir (iphone-6.9 | ipad-13 | visionos)
    python3 - "$1" "$2" <<'PY'
import sys
from PIL import Image
path, dir = sys.argv[1], sys.argv[2]
strips = {"iphone-6.9": (20, 118, 470, 168), "ipad-13": (330, 8, 760, 64)}
box = strips.get(dir)
if box is None:
    sys.exit(0)
px = list(Image.open(path).convert("L").crop(box).getdata())
mean = sum(px) / len(px)
var = sum((p - mean) ** 2 for p in px) / len(px)
sys.exit(0 if var < 36 else 1)
PY
}

shoot_simulator() {  # $1 = device udid, $2 = output subdir, $3 = app path
    local udid="$1" dir="$2" app="$3"
    mkdir -p "$OUT/$dir"
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
    # Other processes on this machine leave shared simulators in dark mode; force light.
    # Dark shots opt in per-launch via -settings.appearance instead.
    xcrun simctl ui "$udid" appearance light >/dev/null 2>&1
    # Apple's canonical marketing status bar: 9:41, full signal, full battery.
    xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged \
        --batteryLevel 100 --cellularMode active --cellularBars 4 \
        --wifiMode active --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1
    xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1
    xcrun simctl install "$udid" "$app" >/dev/null 2>&1 || { echo "  install failed"; return 1; }
    local entry name tab extra try
    for entry in "${SHOTS[@]}"; do
        IFS='|' read -r name tab extra <<< "$entry"
        for try in 1 2 3; do
            xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1
            sleep 1
            # $extra intentionally unquoted: it's a list of launch arguments.
            xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshotMode -ui.lockPortrait -ui.selectedTab "$tab" $extra >/dev/null 2>&1
            sleep 4
            snap "$udid" "$OUT/$dir/$name.png" || continue
            if clean_bar "$OUT/$dir/$name.png" "$dir"; then
                echo "  $dir/$name.png"
                break
            fi
            echo "  $dir/$name.png contaminated status bar, retaking ($try)"
        done
    done
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
