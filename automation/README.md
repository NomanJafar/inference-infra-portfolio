# Daily build automation

A local macOS launchd job runs one task from [PROGRESS.md](../PROGRESS.md) per day using Claude Code headless (`claude -p`), then pushes and writes [DAYLOG.md](../DAYLOG.md). Nothing runs in the cloud; the only network traffic is the normal Claude Code API calls and `git push`.

| File | Role |
|---|---|
| `daily-build.sh` | Wrapper: decides whether a run is due, asks via a macOS dialog (auto-runs after 5 min), locks, runs `claude -p` with the prompt, notifies on finish |
| `daily-prompt.md` | The self-contained instructions the headless session receives |
| `com.noman.portfolio-daily.plist` | launchd agent: 22:00 daily plus at login, to catch a day missed while the Mac was off |

Install / reload:

```bash
cp automation/com.noman.portfolio-daily.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u)/com.noman.portfolio-daily 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.noman.portfolio-daily.plist
```

Manual run: `automation/daily-build.sh --now`. Dry run: `automation/daily-build.sh --dry-run`. Logs: `<portfolio root>/.daily/logs/`.

Permissions for the headless session come from `<portfolio root>/.claude/settings.json` (git, pytest, ruff, venv python, kaggle; denies force-push, repo create/delete, rm -rf, sudo). The run uses `--permission-mode acceptEdits` and `--max-budget-usd 15`.
