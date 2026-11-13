#!/bin/sh
# Builds the macOS package and replaces the app in /Applications with it.
set -eu
cd "$(dirname "$0")/.."

app_name="PLaMo Translate Desktop"
installed="/Applications/$app_name.app"
executable="$installed/Contents/MacOS/plamo-translate-desktop"

PYTHONDONTWRITEBYTECODE=1 scripts/package-macos.sh

package=$(ls -td dist/*-macos-arm64 | head -n1)
rm -f "$(basename "$package").dmg"

if pgrep -f "^$executable" >/dev/null; then
    osascript -e 'tell application id "com.github.tanakh.plamo-translate-desktop" to quit'
    i=0
    while pgrep -f "^$executable" >/dev/null; do
        i=$((i + 1))
        [ "$i" -le 30 ] || { echo "$app_name did not quit within 30 seconds" >&2; exit 1; }
        sleep 1
    done
fi

# Removed, not overwritten: macOS kills a running signed executable (Chrome's host) changed in place.
rm -rf "$installed"
ditto "$package/$app_name.app" "$installed"
codesign --verify --strict "$installed"

open "$installed"
echo "Installed $(basename "$package") into /Applications"
