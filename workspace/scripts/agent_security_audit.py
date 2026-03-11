#!/usr/bin/env python3
"""Unified security + job health audit for main OpenClaw deployment.

职责：
1. 增量扫描 ikol / claw-wiki 最近 session 的敏感操作与 deny 命中
2. 检查当前所有 enabled cron job 的执行状态是否异常
3. 检查 Repo Monitor 是否存在待发送积压
4. 仅在“严重异常”出现且相对上次通知有变化时输出告警；否则输出 NO_ALERTS
"""

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

WORKSPACE = Path('/root/.openclaw/workspace')
STATE_FILE = WORKSPACE / 'audit-state.json'
SESSIONS_BASE = Path('/root/.openclaw/agents')
AGENTS = ['ikol', 'claw-wiki']
DENY_MARKERS = ['denied', 'not allowed']
PENDING_FILE = WORKSPACE / 'ikoL/projects/repo-monitor/pending_notifications.json'
META_KEY = '_meta'

SENSITIVE = {
    'cron': '*',
    'sessions_spawn': '*',
    'subagents': '*',
    'message': {'send'},
    'feishu_doc': {'write', 'append', 'insert', 'update_block', 'delete_block', 'create_table', 'upload_image'},
    'feishu_drive': {'create_folder', 'move', 'delete'},
    'feishu_bitable_create_app': '*',
    'feishu_bitable_create_field': '*',
    'feishu_bitable_create_record': '*',
    'feishu_bitable_update_record': '*',
    'nodes': '*',
}
DETAIL_KEYS = ['to', 'target', 'file_path', 'path', 'jobId', 'id', 'channel', 'doc_token', 'table_id', 'record_id', 'node', 'action']


def load_state():
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding='utf-8'))
        except Exception:
            return {}
    return {}


def save_state(state):
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding='utf-8')


def latest_session_file(agent: str):
    files = sorted((SESSIONS_BASE / agent / 'sessions').glob('*.jsonl'), key=lambda p: p.stat().st_mtime, reverse=True)
    return files[0] if files else None


def sensitive_tool(name: str, action):
    rule = SENSITIVE.get(name)
    if not rule:
        return False
    if rule == '*':
        return True
    return (action or '') in rule


def clip(text: str, n=140):
    text = ' '.join((text or '').split())
    return text if len(text) <= n else text[: n - 1] + '…'


def summarize_args(args: dict):
    pairs = []
    for k in DETAIL_KEYS:
        v = args.get(k)
        if v not in (None, '', [], {}):
            pairs.append(f'{k}={v}')
    if not pairs:
        raw = json.dumps(args, ensure_ascii=False)
        return clip(raw, 120)
    return clip(' | '.join(pairs), 120)


def parse_new_lines(agent: str, path: Path, start_offset: int):
    data = path.read_bytes()
    chunk = data[start_offset:] if start_offset <= len(data) else b''
    text = chunk.decode('utf-8', errors='ignore')
    alerts = []
    for line in text.splitlines():
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue

        typ = obj.get('type')
        if typ == 'message':
            msg = obj.get('message') or {}
            if msg.get('role') != 'assistant':
                continue
            for part in msg.get('content', []) or []:
                if part.get('type') != 'toolCall':
                    continue
                name = part.get('name') or part.get('toolName') or ''
                args = part.get('arguments') or {}
                action = args.get('action')
                if sensitive_tool(name, action):
                    alerts.append({
                        'kind': 'sensitive-tool',
                        'severity': 'critical',
                        'agent': agent,
                        'title': f'Agent {agent} 调用了敏感工具 {name}',
                        'detail': f'action={action or "-"} | {summarize_args(args)}',
                    })
        dump = json.dumps(obj, ensure_ascii=False).lower()
        if any(m in dump for m in DENY_MARKERS):
            alerts.append({
                'kind': 'deny-rule',
                'severity': 'critical',
                'agent': agent,
                'title': f'Agent {agent} 命中 deny / not allowed 规则',
                'detail': clip(json.dumps(obj, ensure_ascii=False), 120),
            })
    return alerts, len(data)


def run_json(cmd):
    out = subprocess.check_output(cmd, text=True)
    return json.loads(out)


def check_repo_monitor_backlog():
    if not PENDING_FILE.exists():
        return []
    try:
        data = json.loads(PENDING_FILE.read_text(encoding='utf-8'))
    except Exception as e:
        return [{
            'kind': 'repo-monitor-backlog',
            'severity': 'critical',
            'title': 'Repo Monitor 待发送队列文件损坏',
            'detail': clip(str(e), 120),
        }]

    if isinstance(data, list):
        unsent = [x for x in data if isinstance(x, dict) and not x.get('sent', False)]
    elif isinstance(data, dict):
        arr = data.get('notifications') or data.get('items') or []
        unsent = [x for x in arr if isinstance(x, dict) and not x.get('sent', False)]
    else:
        unsent = []

    if not unsent:
        return []
    return [{
        'kind': 'repo-monitor-backlog',
        'severity': 'critical',
        'title': f'Repo Monitor 存在 {len(unsent)} 条未发送通知积压',
        'detail': clip(json.dumps(unsent[:3], ensure_ascii=False), 140),
    }]


def check_enabled_jobs():
    try:
        obj = run_json(['openclaw', 'cron', 'list', '--json'])
    except Exception as e:
        return [{
            'kind': 'job-health',
            'severity': 'critical',
            'title': '无法读取 cron job 列表',
            'detail': clip(str(e), 120),
        }]

    jobs = obj.get('jobs') if isinstance(obj, dict) else obj
    alerts = []
    for job in jobs or []:
        if not isinstance(job, dict) or not job.get('enabled'):
            continue
        state = job.get('state') or {}
        name = job.get('name') or job.get('id') or 'unknown-job'
        last_status = state.get('lastRunStatus') or state.get('lastStatus') or 'unknown'
        consecutive = int(state.get('consecutiveErrors') or 0)
        last_error = state.get('lastError') or ''

        is_severe = False
        reasons = []
        if last_status == 'error':
            is_severe = True
            reasons.append('lastRunStatus=error')
        if consecutive >= 2:
            is_severe = True
            reasons.append(f'consecutiveErrors={consecutive}')
        if 'timed out' in last_error.lower():
            is_severe = True
            reasons.append('timeout')

        if is_severe:
            detail = f"job={name} | {' | '.join(reasons)}"
            if last_error:
                detail += f" | error={clip(last_error, 120)}"
            alerts.append({
                'kind': 'job-health',
                'severity': 'critical',
                'title': f'Enabled job 异常：{name}',
                'detail': detail,
            })
    return alerts


def stable_fingerprint(alerts):
    payload = [
        {
            'kind': a.get('kind'),
            'severity': a.get('severity'),
            'title': a.get('title'),
            'detail': a.get('detail'),
            'agent': a.get('agent', ''),
        }
        for a in sorted(alerts, key=lambda x: (x.get('kind', ''), x.get('title', ''), x.get('detail', '')))
    ]
    return hashlib.sha256(json.dumps(payload, ensure_ascii=False, sort_keys=True).encode('utf-8')).hexdigest()


def main():
    state = load_state()
    meta = state.get(META_KEY, {}) if isinstance(state.get(META_KEY), dict) else {}

    all_alerts = []
    for agent in AGENTS:
        latest = latest_session_file(agent)
        if not latest:
            continue
        prev = state.get(agent, {}) if isinstance(state.get(agent), dict) else {}
        offset = 0
        if prev.get('file') == latest.name:
            offset = int(prev.get('offset', 0) or 0)
        alerts, new_offset = parse_new_lines(agent, latest, offset)
        all_alerts.extend(alerts)
        state[agent] = {'file': latest.name, 'offset': new_offset}

    all_alerts.extend(check_enabled_jobs())
    all_alerts.extend(check_repo_monitor_backlog())

    if not all_alerts:
        meta['last_notified_fingerprint'] = ''
        state[META_KEY] = meta
        save_state(state)
        print('NO_ALERTS')
        return

    fingerprint = stable_fingerprint(all_alerts)
    if fingerprint == meta.get('last_notified_fingerprint', ''):
        state[META_KEY] = meta
        save_state(state)
        print('NO_ALERTS')
        return

    meta['last_notified_fingerprint'] = fingerprint
    state[META_KEY] = meta
    save_state(state)

    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    lines = ['🚨 OpenClaw 严重异常告警', f'时间: {now}', '']
    for a in all_alerts[:20]:
        lines.append(f"- {a['title']}")
        lines.append(f"  详情: {a['detail']}")
    if len(all_alerts) > 20:
        lines.append(f'... 其余 {len(all_alerts) - 20} 条已省略')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
