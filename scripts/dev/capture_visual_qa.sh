#!/usr/bin/env bash
# Capture one or more Lanternhouse visual QA screenshots through the in-repo
# visual_scene_capture.tscn harness. This intentionally targets scenes by name
# so agents do not accidentally capture the title screen when they meant town.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/dev/capture_visual_qa.sh [target ...]

Examples:
  scripts/dev/capture_visual_qa.sh town
  scripts/dev/capture_visual_qa.sh town overworld battle
  scripts/dev/capture_visual_qa.sh --all

Options:
  --all              Capture town, overworld, battle, home, cave, dock, forest_clearing.
  --output-dir DIR   Output directory. Default: artifacts/screenshots/visual_qa_<timestamp>.
  --frames N         Process frames to wait before each capture. Default: 12.
  --width N          Xvfb width. Default: 1280.
  --height N         Xvfb height. Default: 720.
  --godot PATH       Godot binary. Default: $GODOT_BIN, then ~/.local/bin/godot, godot, ~/.local/bin/godot4, godot4.
  -h, --help         Show this help.

Each capture writes <target>.png and <target>.json manifest into the output dir.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

resolve_godot_bin() {
  if [[ -n "${GODOT_BIN:-}" ]]; then
    echo "$GODOT_BIN"
    return
  fi
  if [[ -x "${HOME}/.local/bin/godot" ]]; then
    echo "${HOME}/.local/bin/godot"
    return
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return
  fi
  if [[ -x "${HOME}/.local/bin/godot4" ]]; then
    echo "${HOME}/.local/bin/godot4"
    return
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return
  fi
  echo "${HOME}/.local/bin/godot"
}

GODOT_BIN="$(resolve_godot_bin)"
OUTPUT_DIR="${PROJECT_DIR}/artifacts/screenshots/visual_qa_$(date +%Y%m%d_%H%M%S)"
FRAMES="12"
WIDTH="1280"
HEIGHT="720"
declare -a TARGETS=()
declare -a ALL_TARGETS=(town overworld battle home cave dock forest_clearing)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      TARGETS=("${ALL_TARGETS[@]}")
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?--output-dir requires a path}"
      shift 2
      ;;
    --frames)
      FRAMES="${2:?--frames requires a number}"
      shift 2
      ;;
    --width)
      WIDTH="${2:?--width requires a number}"
      shift 2
      ;;
    --height)
      HEIGHT="${2:?--height requires a number}"
      shift 2
      ;;
    --godot)
      GODOT_BIN="${2:?--godot requires a path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(town overworld battle)
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot binary is not executable: $GODOT_BIN" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"

echo "=== Lanternhouse Visual QA Capture ==="
echo "Project: $PROJECT_DIR"
echo "Godot:   $GODOT_BIN"
echo "Output:  $OUTPUT_DIR"
echo "Frames:  $FRAMES"
echo "Targets: ${TARGETS[*]}"
echo

echo "[1/2] Importing assets..."
xvfb-run -a -s "-screen 0 ${WIDTH}x${HEIGHT}x24" \
  timeout 90 "$GODOT_BIN" --headless --audio-driver Dummy --import --quit --path "$PROJECT_DIR" >/dev/null

echo "[2/2] Capturing targets..."
for target in "${TARGETS[@]}"; do
  output="$OUTPUT_DIR/${target}.png"
  manifest="$OUTPUT_DIR/${target}.json"
  log="$OUTPUT_DIR/${target}.log"
  echo "  - $target -> $output"
  set +e
  xvfb-run -a -s "-screen 0 ${WIDTH}x${HEIGHT}x24" \
    timeout 90 "$GODOT_BIN" --rendering-driver opengl3 --audio-driver Dummy --path "$PROJECT_DIR" \
    scenes/dev/visual_scene_capture.tscn -- \
    --target "$target" --output "$output" --manifest "$manifest" --frames "$FRAMES" \
    >"$log" 2>&1
  status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    echo "ERROR: Capture failed for target '$target' (exit $status). Log: $log" >&2
    tail -80 "$log" >&2 || true
    exit "$status"
  fi
  if ! grep -q "VISUAL_SCENE_CAPTURE_OK target=${target}" "$log"; then
    echo "ERROR: Capture log did not confirm expected target '$target'. Log: $log" >&2
    tail -80 "$log" >&2 || true
    exit 3
  fi
  if [[ ! -s "$output" ]]; then
    echo "ERROR: Capture output missing or empty: $output" >&2
    exit 4
  fi
  file "$output"
done

echo
echo "VISUAL_QA_CAPTURE_OK $OUTPUT_DIR"
