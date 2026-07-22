#!/bin/bash
# Captures Mac Catalyst screenshots at 1280x800 points. On a Retina display that
# yields 2560x1600 pixels — an accepted Mac App Store size. (1440x900 points does
# not fit this machine's 1352x853-point built-in display; screencapture clamps the
# region and produces an unusable 2704x1706.)
# Requires Screen Recording permission for the terminal running this script.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Screenshots/mac"
APP_NAME="Game Toolkit"
BUNDLE_ID="com.nathanfennel.Game-Toolkit"
W=1280
H=800
TOP=25          # leave the menu bar out of the capture
cd "$ROOT" || exit 1
mkdir -p "$OUT"

echo "Building Mac Catalyst app..."
# Built unsigned: the shipping entitlements include App Sandbox, which ad-hoc signing can't
# carry. We re-sign ad-hoc (without entitlements) purely so macOS will launch it locally.
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" \
    -destination 'platform=macOS,variant=Mac Catalyst' -configuration Debug \
    CODE_SIGNING_ALLOWED=NO build >/dev/null 2>&1 || {
        echo "build failed"; exit 1; }

BUILD_DIR="$(xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ BUILD_DIR /{print $2; exit}')"
APP="$BUILD_DIR/Debug-maccatalyst/$APP_NAME.app"
[ -d "$APP" ] || { echo "app not found at $APP"; exit 1; }
codesign --force --deep --sign - "$APP" >/dev/null 2>&1

place_window() {
    osascript <<EOF 2>/dev/null
tell application "System Events"
    set i to 0
    repeat until (exists (first process whose name is "$APP_NAME")) or i > 40
        delay 0.25
        set i to i + 1
    end repeat
    tell process "$APP_NAME"
        set frontmost to true
        delay 0.4
        try
            set position of window 1 to {0, $TOP}
            set size of window 1 to {$W, $H}
        end try
    end tell
end tell
EOF
}

shoot() {   # $1 = tab index, $2 = name, $3... = extra args
    local idx="$1" name="$2"; shift 2
    pkill -f "$APP/Contents/MacOS/$APP_NAME" >/dev/null 2>&1
    sleep 1
    open "$APP" --args -screenshotMode -ui.selectedTab "$idx" "$@"
    sleep 4
    place_window
    sleep 1
    screencapture -x -R "0,$TOP,$W,$H" "$OUT/$name.png" && echo "  mac/$name.png"
}

# -settings.appearance light everywhere the shot isn't deliberately dark: the app
# follows the host Mac's system appearance otherwise, and this machine runs dark.
shoot 0 1-dice -settings.appearance light
shoot 1 2-timer -settings.appearance light
shoot 2 3-scores -settings.appearance light
shoot 2 4-chart -showChart -settings.appearance light
shoot 4 5-settings -settings.appearance light
shoot 0 6-theme-gaslight -ui.theme gaslight -settings.appearance dark
shoot 2 7-theme-azul -ui.theme azul -settings.appearance light
shoot 3 8-players -ui.demoGroups -showGallery -settings.appearance light
shoot 1 9-timer-hourglass -timer.styleID hourglass -settings.appearance light
shoot 1 10-timer-analog -timer.styleID analog -settings.appearance light
shoot 0 11-dice-dark -settings.appearance dark
shoot 1 12-theme-wingspan -ui.theme wingspan -settings.appearance light
shoot 0 13-theme-catan -ui.theme catan -settings.appearance light

pkill -f "$APP/Contents/MacOS/$APP_NAME" >/dev/null 2>&1
echo "Done. See $OUT"
