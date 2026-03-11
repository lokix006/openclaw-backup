#!/usr/bin/env python3
"""
Repo Monitor - 监控 GitHub/GitLab 分支更新
检测到变化后写入 pending_notifications.json，由 OpenClaw agent 负责发 Feishu 通知
"""

import csv
import json
import os
import requests
from datetime import datetime, timezone
from pathlib import Path

# ── 路径配置 ──────────────────────────────────────────────
BASE_DIR     = Path(__file__).parent
CSV_FILE     = BASE_DIR / "repos.csv"
STATE_FILE   = BASE_DIR / "repo_state.json"
PENDING_FILE = BASE_DIR / "pending_notifications.json"
ENV_FILE     = BASE_DIR / ".env"

# ── 加载 .env ─────────────────────────────────────────────
def load_env():
    if ENV_FILE.exists():
        with open(ENV_FILE) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

load_env()

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITLAB_TOKEN = os.environ.get("GITLAB_TOKEN", "")
GITLAB_BASE  = os.environ.get("GITLAB_BASE_URL", "https://gitlab.com").rstrip("/")

# ── State ─────────────────────────────────────────────────
def load_state():
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

# ── Pending notifications ─────────────────────────────────
def load_pending():
    if PENDING_FILE.exists():
        with open(PENDING_FILE) as f:
            return json.load(f)
    return []

def save_pending(notifications):
    with open(PENDING_FILE, "w") as f:
        json.dump(notifications, f, indent=2, ensure_ascii=False)

# ── GitHub API ────────────────────────────────────────────
def get_github_latest(repo, branch):
    url = f"https://api.github.com/repos/{repo}/branches/{branch}"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
    }
    resp = requests.get(url, headers=headers, timeout=15)
    resp.raise_for_status()
    data = resp.json()
    commit = data["commit"]
    return {
        "sha": commit["sha"],
        "message": commit["commit"]["message"].split("\n")[0][:120],
        "author": commit["commit"]["author"]["name"],
        "url": commit["html_url"],
        "time": commit["commit"]["author"]["date"],
    }

# ── GitLab API ────────────────────────────────────────────
def get_gitlab_latest(repo, branch):
    encoded = requests.utils.quote(repo, safe="")
    url = f"{GITLAB_BASE}/api/v4/projects/{encoded}/repository/branches/{branch}"
    headers = {"PRIVATE-TOKEN": GITLAB_TOKEN}
    resp = requests.get(url, headers=headers, timeout=15)
    resp.raise_for_status()
    data = resp.json()
    commit = data["commit"]
    return {
        "sha": commit["id"],
        "message": commit["message"].split("\n")[0][:120],
        "author": commit["author_name"],
        "url": commit.get("web_url", ""),
        "time": commit["authored_date"],
    }

# ── 主逻辑 ────────────────────────────────────────────────
def main():
    state   = load_state()
    # 只加载未发送的通知，已发送的自动丢弃
    pending = [p for p in load_pending() if not p.get("sent", False)]
    state_updated   = False
    new_notifications = []

    with open(CSV_FILE, newline="") as f:
        rows = list(csv.DictReader(f))

    for row in rows:
        platform = row["platform"].strip().lower()
        repo     = row["repo"].strip()
        branch   = row["branch"].strip()
        user_ids = [u.strip() for u in row["notify_user_ids"].split(";") if u.strip()]
        key      = f"{platform}:{repo}:{branch}"

        ts = datetime.now(timezone.utc).strftime("%H:%M:%S")
        print(f"[{ts}] 检查 {key} ...", end=" ", flush=True)

        try:
            if platform == "github":
                info = get_github_latest(repo, branch)
            elif platform == "gitlab":
                info = get_gitlab_latest(repo, branch)
            else:
                print(f"未知平台: {platform}")
                continue

            last_sha = state.get(key, {}).get("sha")

            if last_sha is None:
                print(f"首次记录 SHA={info['sha'][:8]}")
                state[key] = {"sha": info["sha"], "checked_at": datetime.now(timezone.utc).isoformat()}
                state_updated = True

            elif last_sha != info["sha"]:
                print(f"有更新！{last_sha[:8]} → {info['sha'][:8]}")
                for uid in user_ids:
                    new_notifications.append({
                        "user_id": uid,
                        "platform": platform,
                        "repo": repo,
                        "branch": branch,
                        "commit": info,
                        "queued_at": datetime.now(timezone.utc).isoformat(),
                        "sent": False,
                    })
                state[key] = {"sha": info["sha"], "checked_at": datetime.now(timezone.utc).isoformat()}
                state_updated = True

            else:
                print(f"无变化 SHA={info['sha'][:8]}")

        except Exception as e:
            print(f"❌ 出错: {e}")

    if state_updated:
        save_state(state)

    # 合并未发送的旧通知 + 新通知，一并写回
    all_pending = pending + new_notifications
    save_pending(all_pending)

    if new_notifications:
        print(f"📬 新增 {len(new_notifications)} 条通知待发送，队列共 {len(all_pending)} 条")
    else:
        print(f"✅ 本次检查完成，待发送队列: {len(all_pending)} 条")

if __name__ == "__main__":
    main()
