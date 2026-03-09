"""
构建 Lark 交互卡片 JSON (V1 格式)
- 通用字段：alertname / grafana_folder / values / 触发时间 / 状态 / 处理人
- 动态扩展：labels 中非系统字段（排除 alertname/grafana_folder/im/job/instance 等）
- 固定链接：Dashboard / Panel / 告警详情 / 静默
"""
import json
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
    "restored":   "🔄 标记已恢复",
    "resolved":   "✅ 标记已解决",
    "ignored":    "🔕 忽略",
}

BTN_TYPES = {
    "processing": "primary",
    "resolved":   "primary",
    "restored":   "default",
    "ignored":    "danger",
}

# 不在动态 labels 区显示的系统/已处理字段
SYSTEM_LABEL_KEYS = {
    "alertname", "grafana_folder", "im", "job", "instance",
    "address", "symbol", "type", "ptype",
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
    # 已知特殊字段
    address: Optional[str] = None,
    symbol: Optional[str] = None,
    alert_type: Optional[str] = None,
    ptype: Optional[str] = None,
    instance: Optional[str] = None,
    handler_name: Optional[str] = None,
    # 链接
    dashboard_url: Optional[str] = None,
    panel_url: Optional[str] = None,
    silence_url: Optional[str] = None,
    generator_url: Optional[str] = None,
    # 动态扩展 labels
    extra_labels: Optional[Dict[str, Any]] = None,
) -> dict:
    cfg = STATE_CONFIG.get(state, STATE_CONFIG["firing"])
    next_states = STATE_TRANSITIONS.get(state, [])

    # ── 头部 ───────────────────────────────────────────────────────────────────
    header = {
        "template": cfg["color"],
        "title": {
            "tag": "plain_text",
            "content": f"{cfg['emoji']} 告警 | {alertname}",
        },
    }

    elements = []

    # ── 核心字段 ───────────────────────────────────────────────────────────────
    def field(label, value):
        return {
            "is_short": True,
            "text": {"tag": "lark_md", "content": f"**{label}**\n{value or '-'}"},
        }

    fields = []

    if grafana_folder:
        fields.append(field("监控目录", grafana_folder))
    if address:
        fields.append(field("合约地址", address))
    if symbol:
        fields.append(field("币种", symbol))
    if alert_type:
        fields.append(field("类型", alert_type))
    if ptype:
        fields.append(field("业务类型", ptype))
    if instance:
        fields.append(field("实例", instance))

    # Values 通用显示
    value_parts = []
    if value_a is not None:
        value_parts.append(f"A={value_a}")
    if value_b is not None:
        value_parts.append(f"B={value_b}")
    if value_c is not None:
        value_parts.append(f"C={value_c}")
    if value_parts:
        fields.append(field("监控值", "  |  ".join(value_parts)))

    fields.append(field("触发时间", starts_at))
    fields.append(field("状态", cfg["label"]))
    if handler_name:
        fields.append(field("处理人", handler_name))

    if fields:
        elements.append({"tag": "div", "fields": fields})

    # ── 动态扩展 labels（排除已知字段后的剩余 labels）──────────────────────────
    if extra_labels:
        filtered = {k: v for k, v in extra_labels.items() if k not in SYSTEM_LABEL_KEYS}
        if filtered:
            ext_fields = [field(k, str(v)) for k, v in filtered.items()]
            # 两两分组
            for i in range(0, len(ext_fields), 2):
                chunk = ext_fields[i:i+2]
                elements.append({"tag": "div", "fields": chunk})

    # ── 链接区 ─────────────────────────────────────────────────────────────────
    links = []
    if dashboard_url:
        links.append(f"[📊 Dashboard]({dashboard_url})")
    if panel_url:
        links.append(f"[📈 Panel]({panel_url})")
    if generator_url:
        links.append(f"[📋 告警详情]({generator_url})")
    if silence_url:
        links.append(f"[🔇 静默]({silence_url})")
    if links:
        elements.append({
            "tag": "div",
            "text": {"tag": "lark_md", "content": "  |  ".join(links)},
        })

    # ── 分割线 + 操作按钮 ───────────────────────────────────────────────────────
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
