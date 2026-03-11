---
name: repo-monitor
description: Monitor GitHub/GitLab repository branches for new commits and send Feishu notifications. Use when user asks to check repository updates, view monitoring list, add/remove repos, manually trigger a check, or query latest commit status. Trigger on phrases like "仓库有更新吗", "查看监控列表", "添加仓库监控", "删除仓库", "手动检查", "最新提交", "repo monitor", "repository update".
---

# Repo Monitor Skill

Manages a repository monitoring system that detects branch updates and notifies Feishu users.

## Architecture

```
ikol (this agent)               main agent (via cron job)
├── Read operations             ├── Runs monitor.py every 5 min
│   ├── View repos list         ├── Detects new commits
│   ├── View latest state       ├── Writes pending_notifications.json
│   └── View pending queue      └── Sends Feishu DM notifications
└── Write operations (delegate to main via cron)
    ├── Add/remove repo
    └── Manual trigger check
```

## Data Files

All files live in `/root/.openclaw/workspace/ikoL/projects/repo-monitor/`:

| File | Purpose |
|------|---------|
| `repos.csv` | Monitored repo list (platform,repo,branch,notify_user_ids) |
| `repo_state.json` | Last known SHA per repo:branch |
| `pending_notifications.json` | Queue of unsent notifications (sent field) |
| `.env` | GITHUB_TOKEN, GITLAB_TOKEN, GITLAB_BASE_URL |

## Read Operations (do directly)

### View monitoring list
Read `repos.csv` and format as table. Fields: platform, repo, branch, notify_user_ids (semicolon-separated).

### View latest commit state
Read `repo_state.json`. Show sha (first 8 chars), checked_at per repo.

### View pending queue
Read `pending_notifications.json`. Show unsent items (sent=false).

## Write Operations (delegate to main agent via cron)

**IMPORTANT**: This agent (ikol) has exec denied. For operations that require running scripts or modifying repos.csv, create a one-shot cron job delegated to main agent.

### Add a repo to monitoring
1. Confirm with user: platform (github/gitlab), repo (owner/name), branch, notify_user_ids (semicolon-separated feishu user IDs)
2. Create one-shot cron job:
```
cron.add({
  name: "repo-monitor: add <repo>",
  agentId: "main",
  sessionTarget: "isolated",
  schedule: { kind: "at", at: "<now+10s>" },
  payload: {
    kind: "agentTurn",
    message: "Append this line to /root/.openclaw/workspace/ikoL/projects/repo-monitor/repos.csv (do not overwrite, append only):\n<platform>,<repo>,<branch>,<user_ids>\nThen reply DONE."
  },
  delivery: { mode: "none" }
})
```
3. Tell user: "已委托添加，稍后生效"

### Remove a repo from monitoring
1. Show current list, confirm which line to remove
2. Create one-shot cron job delegating to main to remove the specific line from repos.csv
3. Tell user: "已委托删除，稍后生效"

### Manual trigger check
Create a one-shot cron job:
```
cron.add({
  name: "repo-monitor: manual check",
  agentId: "main",
  sessionTarget: "isolated",
  schedule: { kind: "at", at: "<now+5s>" },
  payload: {
    kind: "agentTurn",
    message: "Run: exec python3 /root/.openclaw/workspace/ikoL/projects/repo-monitor/monitor.py\nThen read pending_notifications.json, send feishu DM for each sent=false item via message tool (channel=feishu, accountId=feishu-loki, target=user:<user_id>), mark sent=true, remove sent items. Reply DONE when finished."
  },
  delivery: { mode: "none" }
})
```
Tell user: "已触发手动检查，30秒内完成"

## Notification Format (for reference)

When main agent sends notifications, format:
```
📦 仓库更新通知
仓库：<platform>/<repo>
分支：<branch>
提交者：<commit.author>
提交信息：<commit.message>
时间：<commit.time>
链接：<commit.url>
```

## refs/repos-csv-format.md

See `references/repos-csv-format.md` for CSV format details and examples.
