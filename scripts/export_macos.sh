#!/usr/bin/env bash
# Export a macOS release zip into ./build/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
OUT_DIR="$ROOT/build"
OUT_ZIP="$OUT_DIR/NeonStack.zip"

mkdir -p "$OUT_DIR"
echo "Exporting Neon Stack (macOS) → $OUT_ZIP"
"$GODOT" --headless --path "$ROOT" --export-release "macOS" "$OUT_ZIP"
echo "Done."
ls -lh "$OUT_ZIP"
