"""
构建 Lark 交互卡片 JSON (V1 格式 + column_set 分栏布局)

布局层次（紧凑版）：
  Header    — 状态色 + 告警名
  Links     — 链接工具栏（紧跟 header）
  Divider
  Info      — column_set 双列：左=监控值+状态，右=目录/类型/地址等
  Meta      — 触发时间 · 处理人（灰色背景）
  Extra     — 动态扩展 labels（有才显示）
  Details   — 多告警明细（有才显示）
  Divider
  Buttons   — 操作按钮
"""
from typing import Optional, Dict, Any

STATE_CONFIG = {
    "firing":     {"color": "red",    "label": "🔴 Firing",     "emoji": "🚨"},
    "processing": {"color": "orange", "label": "🟠 Processing", "emoji": "🔧"},
    "restored":   {"color": "blue",   "label": "🔵 Restored",   "emoji": "🔄"},
    "resolved":   {"color": "green",  "label": "✅ Resolved",   "emoji": "✅"},
    "ignored":    {"color": "grey",   "label": "⚪ Ignored",    "emoji": "🔕"},
}

STATE_TRANSITIONS = {
    "firing":     ["processing", "ignored"],
    "processing": ["restored", "resolved", "ignored"],
    "restored":   ["processing", "resolved"],
    "resolved":   [],
    "ignored":    [],
}

ACTION_LABELS = {
    "processing": "🔧 接管处理",
    "restored":   "🔄 已恢复",
    "resolved":   "✅ 已解决",
    "ignored":    "🔕 忽略",
}

BTN_TYPES = {
    "processing": "primary",
    "resolved":   "primary",
    "restored":   "default",
    "ignored":    "danger",
}

SYSTEM_LABEL_KEYS = {
    "alertname", "grafana_folder", "im", "job", "instance",
    "address", "symbol", "type", "ptype",
}


def _md(content: str, align: str = "left") -> dict:
    return {"tag": "markdown", "content": content, "text_align": align}


def _col(elements: list, weight: int = 1, align: str = "top") -> dict:
    return {
        "tag": "column",
        "width": "weighted",
        "weight": weight,
        "vertical_align": align,
        "elements": elements,
    }


def _col_set(columns: list, flex_mode: str = "none", bg: str = "default", spacing: str = "small") -> dict:
    return {
        "tag": "column_set",
        "flex_mode": flex_mode,
        "background_style": bg,
        "horizontal_spacing": spacing,
        "columns": columns,
    }


def build_alert_card(
    alert_id: str,
    alertname: str,
    grafana_folder: Optional[str],
    value_a: Optional[float],
    value_b: Optional[float],
    value_c: Optional[float],
    starts_at: str,
    state: str,
    address: Optional[str] = None,
    symbol: Optional[str] = None,
    alert_type: Optional[str] = None,
    ptype: Optional[str] = None,
    instance: Optional[str] = None,
    handler_name: Optional[str] = None,
    dashboard_url: Optional[str] = None,
    panel_url: Optional[str] = None,
    silence_url: Optional[str] = None,
    generator_url: Optional[str] = None,
    extra_labels: Optional[Dict[str, Any]] = None,
    multi_info: Optional[str] = None,
    alert_count: int = 1,
) -> dict:
    cfg = STATE_CONFIG.get(state, STATE_CONFIG["firing"])
    next_states = STATE_TRANSITIONS.get(state, [])
    count_suffix = f"({alert_count}条) " if alert_count > 1 else ""

    # ── Header ────────────────────────────────────────────────────────────────
    # title: 状态 emoji（大字）/ subtitle: alertname（小一号）
    header = {
        "template": cfg["color"],
        "title": {
            "tag": "plain_text",
            "content": f"{cfg['emoji']} {cfg['label']} {count_suffix}",
        },
        "subtitle": {
            "tag": "plain_text",
            "content": alertname,
        },
    }

    elements = []

    # ── Layer 1: 链接工具栏（紧跟标题）──────────────────────────────────────
    links = []
    if dashboard_url:
        links.append(f"[Dashboard]({dashboard_url})")
    if panel_url:
        links.append(f"[Panel]({panel_url})")
    if generator_url:
        links.append(f"[告警详情]({generator_url})")
    if silence_url:
        links.append(f"[静默]({silence_url})")
    if links:
        elements.append(_md("  ·  ".join(links)))

    elements.append({"tag": "hr"})

    # ── Layer 2: 第一行 — 监控值（左） + 目录/环境信息（右）─────────────────
    value_parts = []
    if value_a is not None:
        value_parts.append(f"A={value_a}")
    if value_b is not None:
        value_parts.append(f"B={value_b}")
    if value_c is not None:
        value_parts.append(f"C={value_c}")

    value_text = f"**监控值** {' | '.join(value_parts)}" if value_parts else "**监控值** -"

    right_lines = []
    if grafana_folder:
        right_lines.append(f"**目录** {grafana_folder}")
    if address:
        right_lines.append(f"**地址** {address}")
    if symbol:
        right_lines.append(f"**币种** {symbol}")
    if alert_type:
        right_lines.append(f"**类型** {alert_type}")
    if ptype:
        right_lines.append(f"**业务** {ptype}")
    if instance:
        right_lines.append(f"**实例** {instance}")

    left_col1 = _col([_md(value_text)], weight=1)
    right_col1 = _col([_md("  ·  ".join(right_lines) if right_lines else "-")], weight=1)
    elements.append(_col_set([left_col1, right_col1], flex_mode="bisect", spacing="large"))

    # ── Layer 3: 第二行 — 触发时间（左） + 处理人（右），行间距拉开 ──────────
    time_text = f"🕐 {starts_at}"
    handler_text = f"👤 {handler_name}" if handler_name else "👤 -"
    left_col2 = _col([_md(time_text)], weight=1)
    right_col2 = _col([_md(handler_text)], weight=1)
    elements.append(_col_set(
        [left_col2, right_col2],
        flex_mode="bisect",
        bg="grey",
        spacing="large",
    ))

    # ── Layer 4: 动态扩展 labels — 已移除，不再显示额外 labels ──────────────

    # ── Layer 5: 多告警明细（有才显示）───────────────────────────────────────
    if multi_info:
        elements.append({"tag": "hr"})
        elements.append(_md(f"**明细**\n{multi_info}"))

    # ── 操作按钮 ───────────────────────────────────────────────────────────────
    if next_states:
        elements.append({"tag": "hr"})
        btns = []
        for ns in next_states:
            btns.append({
                "tag": "button",
                "text": {"tag": "plain_text", "content": ACTION_LABELS.get(ns, ns)},
                "type": BTN_TYPES.get(ns, "default"),
                "value": {"action": ns, "alert_id": alert_id},
            })
        elements.append({"tag": "action", "actions": btns})

    return {
        "config": {"wide_screen_mode": True},
        "header": header,
        "elements": elements,
    }
