#!/bin/bash
# Rebuilds the dialogue map (every line, choice and outcome, with mp3 status) into build/dialogue_map/.
#   GODOT=/path/to/godot tools/dialogue_map/build.sh
# Then republish to the map's artifact (slug in HANDOFF.md, "Dialogue map"): index.html, dialogue.json and any voices/**
# file that's new or changed (publish_files, mode patch; compare with list_files' sha256). Max 256 files per call.
set -e
cd "$(dirname "$0")/../.."
G=${GODOT:-godot}
export DLG_DIR=${DLG_DIR:-/tmp/dlg}
mkdir -p "$DLG_DIR"
echo '[]' > "$DLG_DIR/extra_texts.json"
"$G" --headless --path godot --script res://tools/dialogue_map_dump.gd 2>&1 | grep -E "DUMPED" || true
python3 tools/dialogue_map/build.py build/dialogue_map > /dev/null || true   # first pass: collects the level-code lines
"$G" --headless --path godot --script res://tools/dialogue_map_dump.gd 2>&1 | grep -E "DUMPED" || true
python3 tools/dialogue_map/build.py build/dialogue_map
