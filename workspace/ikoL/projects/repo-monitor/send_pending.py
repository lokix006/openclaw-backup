#!/usr/bin/env python3
"""Send pending repo-monitor notifications via OpenClaw CLI and clear sent items."""

import json
import subprocess
from datetime import datetime, timezone, timedelta
from pathlib import Path

BASE_DIR = Path(__file__).parent
PENDING_FILE = BASE_DIR / 'pending_notifications.json'
ACCOUNT = 'feishu-loki'


def load_pending():
    if not PENDING_FILE.exists():
        return []
    return json.loads(PENDING_FILE.read_text(encoding='utf-8'))


def save_pending(items):
    PENDING_FILE.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding='utf-8')


def fmt_time(ts: str) -> str:
    try:
        cst = timezone(timedelta(hours=8))
        dt = datetime.fromisoformat(ts.replace('Z', '+00:00')).astimezone(cst)
        return dt.strftime('%Y-%m-%d %H:%M CST')
    except Exception:
        return ts


def build_message(item: dict) -> str:
    commit = item.get('commit', {})
    repo = item.get('repo', '-')
    branch = item.get('branch', '-')
    author = commit.get('author', '-')
    message = (commit.get('message') or '-').replace('|', '｜')
    url = commit.get('url', '')
    ctime = fmt_time(commit.get('time', '-'))
    return (
        '📦 **仓库更新通知**\n\n'
        f'**{repo}** · `{branch}`\n\n'
        '| 字段 | 内容 |\n'
        '|------|------|\n'
        f'| 👤 提交者 | {author} |\n'
        f'| 💬 提交信息 | {message} |\n'
        f'| 🕐 时间 | {ctime} |\n'
        f'| 🔗 链接 | [查看 Commit]({url}) |\n'
    )


def send_one(item: dict):
    target = item.get('user_id', '').strip()
    if not target:
        raise RuntimeError('missing user_id')
    msg = build_message(item)
    proc = subprocess.run(
        [
            'openclaw', 'message', 'send',
            '--channel', 'feishu',
            '--account', ACCOUNT,
            '--target', target,
            '--message', msg,
            '--json',
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout.strip() or proc.stderr.strip()


def main():
    pending = load_pending()
    sent_count = 0
    failed = []
    kept = []

    for item in pending:
        if item.get('sent', False):
            continue
        try:
            receipt = send_one(item)
            item['sent'] = True
            item['sent_at'] = datetime.now(timezone.utc).isoformat()
            item['receipt'] = receipt[:500]
            sent_count += 1
        except Exception as e:
            item['last_error'] = str(e)[:500]
            failed.append({
                'repo': item.get('repo'),
                'branch': item.get('branch'),
                'user_id': item.get('user_id'),
                'error': str(e)[:200],
            })
            kept.append(item)

    save_pending(kept)
    print(json.dumps({
        'sent_count': sent_count,
        'remaining_count': len(kept),
        'failed': failed[:10],
    }, ensure_ascii=False))


if __name__ == '__main__':
    main()
