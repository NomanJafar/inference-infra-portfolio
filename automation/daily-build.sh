#!/usr/bin/env bash
# Daily portfolio build. Invoked by launchd at 22:00 and at login (to catch a missed day).
#   ./daily-build.sh            normal: decide if a run is due, ask via dialog, run
#   ./daily-build.sh --now      skip the due-check and the dialog, run immediately
#   ./daily-build.sh --dry-run  print what would happen, run nothing
set -uo pipefail
# This file lives in <portfolio root>/inference-infra-portfolio/automation/
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE="$ROOT/.daily"; LOGS="$STATE/logs"; LAST="$STATE/last_run"; LOCK="$STATE/lock"
mkdir -p "$LOGS"
TODAY=$(date +%F); HOUR=$(date +%H); NOW=$(date "+%F %T")
MODE="${1:-}"
log() { echo "[$NOW] $*" >> "$LOGS/daily-build.log"; }

# Locate the Claude Code CLI: PATH first, else the newest VS Code extension bundle.
CLI=$(command -v claude || true)
if [ -z "$CLI" ]; then
  CLI=$(ls -d "$HOME"/.vscode/extensions/anthropic.claude-code-*-darwin-arm64/resources/native-binary/claude 2>/dev/null | sort -V | tail -1)
fi
[ -x "${CLI:-}" ] || { log "no claude CLI found"; exit 1; }

# Due if no run today and (it's 22:00 or later, or the last run is older than yesterday).
last=$(cat "$LAST" 2>/dev/null || echo "never")
yesterday=$(date -v-1d +%F)
due=no
if [ "$last" != "$TODAY" ]; then
  if [ "$HOUR" -ge 22 ] || [[ "$last" < "$yesterday" ]]; then due=yes; fi
fi
if [ "$MODE" = "--dry-run" ]; then
  echo "cli=$CLI last_run=$last today=$TODAY hour=$HOUR due=$due"; exit 0
fi
if [ "$MODE" != "--now" ]; then
  [ "$due" = yes ] || { log "not due (last=$last)"; exit 0; }
  # Ask. Defaults to Run after 5 minutes so an unattended night still builds.
  answer=$(osascript -e 'display dialog "Portfolio daily build: run today'"'"'s task now?\n(Runs automatically in 5 minutes.)" buttons {"Skip today","Run"} default button "Run" with title "inference-infra-portfolio" giving up after 300' 2>/dev/null)
  if echo "$answer" | grep -q "Skip today"; then
    echo "$TODAY" > "$LAST"; log "skipped by user"; exit 0
  fi
fi

if ! mkdir "$LOCK" 2>/dev/null; then
  # stale lock (older than 6 h) is removed; otherwise another run is in progress
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +360 2>/dev/null)" ]; then rmdir "$LOCK"; mkdir "$LOCK"; else log "already running"; exit 0; fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$ROOT"
RUNLOG="$LOGS/$TODAY.log"
log "starting run -> $RUNLOG"
osascript -e 'display notification "Daily build started" with title "inference-infra-portfolio"' 2>/dev/null || true

"$CLI" -p "$(cat "$ROOT/inference-infra-portfolio/automation/daily-prompt.md")" \
  --permission-mode acceptEdits \
  --max-budget-usd 15 \
  --output-format text \
  > "$RUNLOG" 2>&1
status=$?
echo "$TODAY" > "$LAST"
log "finished with status $status"
if [ $status -eq 0 ]; then
  osascript -e 'display notification "Daily build finished. Read DAYLOG.md." with title "inference-infra-portfolio"' 2>/dev/null || true
else
  osascript -e "display notification \"Daily build FAILED (status $status). See .daily/logs/$TODAY.log\" with title \"inference-infra-portfolio\"" 2>/dev/null || true
fi
exit $status
