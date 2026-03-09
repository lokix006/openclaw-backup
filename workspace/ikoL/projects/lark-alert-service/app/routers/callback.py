"""
模块2: Lark 事件回调 — 处理卡片按钮点击，更新告警状态
"""
import json
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import AlertRecord
from app.database import get_db
from app import lark_client, card_builder

router = APIRouter()
logger = logging.getLogger(__name__)

# 合法状态流转表
VALID_TRANSITIONS = {
    "firing":     ["processing", "ignored"],
    "processing": ["restored", "resolved", "ignored"],
    "restored":   ["processing", "resolved"],
}


@router.post("/lark-callback")
async def lark_callback(request: Request, db: AsyncSession = Depends(get_db)):
    body = await request.json()

    # ── URL 验证握手 (Lark Event Subscription 初次验证)
    if body.get("type") == "url_verification":
        return {"challenge": body.get("challenge")}

    header = body.get("header", {})
    event_type = header.get("event_type", "")

    # ── 卡片按钮点击事件
    if event_type == "card.action.trigger":
        event = body.get("event", {})
        action = event.get("action", {})
        operator = event.get("operator", {})

        logger.info(f"[callback] raw body keys: {list(body.keys())}")
        logger.info(f"[callback] event keys: {list(event.keys())}")
        logger.info(f"[callback] action: {action}")

        # Lark 回调的 value 可能被双重 JSON 编码，需要循环 loads 直到得到 dict
        import json as _json
        raw_value = action.get("value", "{}")
        action_value = raw_value
        for _ in range(3):
            if isinstance(action_value, dict):
                break
            if isinstance(action_value, str):
                try:
                    action_value = _json.loads(action_value)
                except Exception:
                    action_value = {}
                    break
            else:
                action_value = {}
                break

        target_state = action_value.get("action")
        alert_id = action_value.get("alert_id")
        operator_open_id = operator.get("open_id", "")
        # name 字段 Lark 回调不一定返回，fallback 到 open_id 缩写
        operator_name = operator.get("name") or operator_open_id[:12] or "Unknown"

        if not alert_id or not target_state:
            return {"code": 400, "msg": "missing alert_id or action"}

        # 查告警记录
        stmt = select(AlertRecord).where(AlertRecord.id == alert_id)
        result = await db.execute(stmt)
        record = result.scalar_one_or_none()

        if not record:
            logger.warning(f"Alert not found: {alert_id}")
            return {"code": 404, "msg": "alert not found"}

        # 状态机校验
        allowed = VALID_TRANSITIONS.get(record.state, [])
        if target_state not in allowed:
            logger.warning(f"Invalid transition: {record.state} → {target_state}")
            return {
                "toast": {
                    "type": "error",
                    "content": f"不允许的状态变更：{record.state} → {target_state}",
                }
            }

        # 更新记录
        old_state = record.state
        record.state = target_state
        record.updated_at = datetime.utcnow()

        if target_state == "processing" and not record.handler:
            record.handler = operator_open_id
            record.handler_name = operator_name

        if target_state in ("resolved", "ignored"):
            record.resolved_at = datetime.utcnow()

        history = json.loads(record.history or "[]")
        history.append({
            "time": datetime.utcnow().isoformat(),
            "event": f"{old_state} → {target_state}",
            "operator": operator_name,
            "open_id": operator_open_id,
        })
        record.history = json.dumps(history, ensure_ascii=False)
        await db.commit()
        logger.info(f"Alert {alert_id} state: {old_state} → {target_state} by {operator_name}")

        # 刷新卡片
        import json as _json2
        starts_at_str = record.starts_at.strftime("%Y-%m-%d %H:%M:%S UTC") if record.starts_at else "-"
        extra_labels = {}
        try:
            extra_labels = _json2.loads(record.raw_labels or "{}")
        except Exception:
            pass
        card = card_builder.build_alert_card(
            alert_id=record.id,
            alertname=record.alertname,
            grafana_folder=record.grafana_folder,
            address=record.address,
            symbol=record.symbol,
            alert_type=record.alert_type,
            ptype=record.ptype,
            instance=getattr(record, 'instance', None),
            value_a=record.value_a,
            value_b=record.value_b,
            value_c=record.value_c,
            starts_at=starts_at_str,
            state=record.state,
            handler_name=record.handler_name,
            dashboard_url=record.dashboard_url,
            panel_url=getattr(record, 'panel_url', None),
            silence_url=record.silence_url,
            generator_url=record.generator_url,
            extra_labels=extra_labels,
        )

        action_label = {"processing": "已接管", "restored": "已标记恢复",
                        "resolved": "已标记解决", "ignored": "已忽略"}

        logger.info(f"[callback] returning card for state={target_state}, card={json.dumps(card, ensure_ascii=False)}")

        # 通过 response body 更新卡片（待确认 Lark 正确格式后调整）
        return {
            "toast": {
                "type": "success",
                "content": f"{action_label.get(target_state, target_state)} ✅",
            },
            "card": {
                "type": "raw",
                "data": card,
            },
        }

    # 其他事件类型 — 忽略
    return {"code": 200, "msg": "ok"}
