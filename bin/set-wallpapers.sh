#!/usr/bin/env bash
# Set wallpapers for all connected displays.
# Run once per machine after dropping your images into home/.config/wallpapers/.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WALL="$DIR/home/.config/wallpapers"

# Count how many desktops (displays) are connected.
COUNT=$(osascript -e 'tell application "System Events" to count every desktop')
echo "Detected $COUNT display(s)."

echo "Use the same wallpaper on all displays? [Y/n]"
read -r SAME

args=(-e "tell application \"System Events\"")
if [[ "$SAME" =~ ^[Nn] ]]; then
  for i in $(seq 1 "$COUNT"); do
    img="$WALL/display-$i.jpg"
    if [ -s "$img" ]; then
      echo "  Setting display-$i.jpg -> desktop $i"
      args+=(-e "set picture of desktop $i to \"$img\"")
    else
      echo "  WARNING: $img is empty or missing - skipping desktop $i"
    fi
  done
else
  img="$WALL/display-1.jpg"
  if [ -s "$img" ]; then
    echo "  Setting display-1.jpg -> all $COUNT displays"
    for i in $(seq 1 "$COUNT"); do
      args+=(-e "set picture of desktop $i to \"$img\"")
    done
  else
    echo "  ERROR: $img is empty or missing - nothing to set"
    exit 1
  fi
fi
args+=(-e "end tell")
osascript "${args[@]}"
echo "Done."
