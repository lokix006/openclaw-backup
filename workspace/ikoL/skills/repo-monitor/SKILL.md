---
name: repo-monitor
description: Monitor GitHub/GitLab repository branches for new commits and send Feishu notifications. Use when user asks to check repository updates, view monitoring list, add/remove repos, manually trigger a check, or query latest commit status. Trigger on phrases like "仓库有更新吗", "查看监控列表", "添加仓库监控", "删除仓库", "手动检查", "最新提交", "repo monitor", "repository update".
---

# Repo Monitor Skill

Manages a repository monitoring system that detects branch updates and notifies Feishu users.

## Architecture

```
ikol (this agent)                    main agent cron job (2f9aa65b)
├── Config management                ├── Runs monitor.py every 5 min
│   ├── View repos list              ├── Detects new commits
│   ├── Add repo (write CSV)         ├── Writes pending_notifications.json
│   └── Remove repo (edit CSV)       └── Sends Feishu DM notifications
└── Query state
    ├── View latest commit state
    └── View pending queue
```

**Manual trigger**: Not needed. Cron job runs every 5 minutes automatically. Tell user to wait up to 5 minutes.

## Data Files

All files in `/root/.openclaw/workspace/ikoL/projects/repo-monitor/`:

| File | Purpose |
|------|---------|
| `repos.csv` | Monitored repo list |
| `repo_state.json` | Last known SHA per repo:branch |
| `pending_notifications.json` | Notification queue |
| `.env` | API tokens (do not read/display) |

## Operations

### View monitoring list
Read `repos.csv` and format as table. Fields: platform, repo, branch, notify_user_ids (semicolon-separated).

### Add a repo
1. Confirm: platform (github/gitlab), repo (owner/name), branch, notify_user_ids (feishu open_ids, semicolon-separated)
2. Append new line to `repos.csv` using `write` tool (read first, then write full file with new line added)
3. Reply: "已添加，下次检查（最多5分钟）生效"

### Remove a repo
1. Show current list, confirm which entry to remove
2. Edit `repos.csv` to remove the specific line using `edit` tool
3. Reply: "已删除"

### View latest commit state
Read `repo_state.json`. Show sha (first 8 chars) and checked_at per repo.

### View pending queue
Read `pending_notifications.json`. Show unsent items (sent=false).

## Notes
- `.env` file contains secrets — never read or display its contents
- CSV format: `platform,repo,branch,notify_user_ids` — see references/repos-csv-format.md
- Notifications are sent by the main agent cron job, not by this agent
