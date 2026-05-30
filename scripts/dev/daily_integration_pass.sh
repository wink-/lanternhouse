#!/usr/bin/env bash
# Run a compact end-of-batch integration pass for Lanternhouse.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/dev/daily_integration_pass.sh [--visual-default|--visual-all|--no-visual]

Runs:
- workflow preflight
- git status summary
- town layout validator when available
- Godot import/parse smoke
- optional visual QA capture
- kanban crash watchdog

It prints proof paths and leaves screenshots under artifacts/screenshots/.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot4}"
VISUAL_MODE="default"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --visual-default) VISUAL_MODE="default"; shift ;;
    --visual-all) VISUAL_MODE="all"; shift ;;
    --no-visual) VISUAL_MODE="none"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

cd "$PROJECT_DIR"
LOG_DIR="artifacts/logs/integration_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

echo "=== Lanternhouse Daily Integration Pass ==="
echo "Project: $PROJECT_DIR"
echo "Logs:    $PROJECT_DIR/$LOG_DIR"
echo

echo "[1/6] Preflight"
python scripts/dev/lanternhouse_workflow_preflight.py | tee "$LOG_DIR/preflight.log"

echo
echo "[2/6] Git status"
git status --short --branch | tee "$LOG_DIR/git-status.log"

echo
echo "[3/6] Layout validation"
if [[ -f scripts/dev/validate_town_layout.py ]]; then
  python scripts/dev/validate_town_layout.py | tee "$LOG_DIR/validate-town-layout.log"
else
  echo "SKIP: no town layout validator" | tee "$LOG_DIR/validate-town-layout.log"
fi

echo
echo "[4/6] Godot import/parse smoke"
timeout 90 "$GODOT_BIN" --headless --audio-driver Dummy --path . --quit >"$LOG_DIR/godot-quit.log" 2>&1 || {
  echo "FAIL: Godot quit/import smoke. Log: $PROJECT_DIR/$LOG_DIR/godot-quit.log" >&2
  tail -80 "$LOG_DIR/godot-quit.log" >&2 || true
  exit 1
}
echo "GODOT_PARSE_OK log=$PROJECT_DIR/$LOG_DIR/godot-quit.log"

echo
echo "[5/6] Visual QA"
case "$VISUAL_MODE" in
  none)
    echo "SKIP: visual capture disabled"
    ;;
  all)
    scripts/dev/capture_visual_qa.sh --all | tee "$LOG_DIR/visual-qa.log"
    ;;
  default)
    scripts/dev/capture_visual_qa.sh town overworld battle | tee "$LOG_DIR/visual-qa.log"
    ;;
esac

echo
echo "[6/6] Kanban crash watchdog"
python scripts/dev/kanban_crash_watchdog.py --board 2d-game --threshold 3 | tee "$LOG_DIR/kanban-crash-watchdog.log"

echo
echo "DAILY_INTEGRATION_PASS_OK logs=$PROJECT_DIR/$LOG_DIR"
