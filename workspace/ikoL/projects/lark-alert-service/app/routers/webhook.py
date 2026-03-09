"""
模块1: 接收 Grafana Webhook → 解析 → 持久化 → 推送 Lark 卡片

合并策略：同一个 groupKey 的 payload 合并为一条记录/一张卡片。
- firing: 新建或重新发卡片
- resolved: 更新状态为 restored
"""
import json
import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.schemas import GrafanaWebhookPayload
from app.models import AlertRecord
from app.database import get_db
from app.config import settings
from app import lark_client, card_builder

router = APIRouter()
logger = logging.getLogger(__name__)


def _parse_starts_at(s: str) -> datetime:
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).replace(tzinfo=None)
    except Exception:
        return datetime.utcnow()


def _build_card_from_record(record: AlertRecord, starts_at_str: str) -> dict:
    """从 AlertRecord 构建卡片，支持多告警合并展示"""
    # 解析合并的 alerts 列表
    alerts_data = []
    try:
        alerts_data = json.loads(record.alerts_json or "[]")
    except Exception:
        pass

    extra_labels = {}
    try:
        extra_labels = json.loads(record.raw_labels or "{}")
    except Exception:
        pass

    # 如果有多条合并的告警，构建扩展信息
    multi_info = None
    if len(alerts_data) > 1:
        lines = []
        for i, a in enumerate(alerts_data, 1):
            parts = []
            for k, v in a.get("labels", {}).items():
                if k not in {"alertname", "grafana_folder", "im", "job"}:
                    parts.append(f"{k}={v}")
            values = a.get("values", {})
            val_str = " | ".join(f"{k}={v}" for k, v in values.items())
            lines.append(f"#{i} {', '.join(parts)}  [{val_str}]")
        multi_info = "\n".join(lines)

    return card_builder.build_alert_card(
        alert_id=record.id,
        alertname=record.alertname,
        grafana_folder=record.grafana_folder,
        address=record.address,
        symbol=record.symbol,
        alert_type=record.alert_type,
        ptype=record.ptype,
        instance=record.instance,
        value_a=record.value_a,
        value_b=record.value_b,
        value_c=record.value_c,
        starts_at=starts_at_str,
        state=record.state,
        handler_name=record.handler_name,
        dashboard_url=record.dashboard_url,
        panel_url=record.panel_url,
        silence_url=record.silence_url,
        generator_url=record.generator_url,
        extra_labels=extra_labels,
        multi_info=multi_info,
        alert_count=len(alerts_data) if alerts_data else 1,
    )


@router.post("/grafana-webhook")
async def grafana_webhook(payload: GrafanaWebhookPayload, db: AsyncSession = Depends(get_db)):
    """
    接收 Grafana Alertmanager Webhook。
    同一 groupKey 的 payload 合并为一条记录/一张卡片。
    """
    if not payload.alerts:
        return {"code": 200, "results": []}

    group_key = payload.groupKey or ""
    common_labels = payload.commonLabels or {}
    status = payload.status  # firing / resolved

    alertname = common_labels.get("alertname") or payload.groupLabels.get("alertname", "Unknown Alert")
    grafana_folder = common_labels.get("grafana_folder")
    address = common_labels.get("address")
    symbol = common_labels.get("symbol")
    alert_type = common_labels.get("type")
    ptype = common_labels.get("ptype")
    instance = common_labels.get("instance")

    # 取第一条 alert 的代表性数据
    first = payload.alerts[0]
    values = first.values or {}
    value_a = values.get("A")
    value_b = values.get("B")
    value_c = values.get("C")
    starts_at_dt = _parse_starts_at(first.startsAt)
    starts_at_str = starts_at_dt.strftime("%Y-%m-%d %H:%M:%S UTC")

    # 所有 alerts 序列化存储
    alerts_json_data = [
        {
            "fingerprint": a.fingerprint,
            "status": a.status,
            "labels": a.labels,
            "values": a.values or {},
            "startsAt": a.startsAt,
        }
        for a in payload.alerts
    ]

    # 查是否已有相同 groupKey 的活跃告警
    stmt = select(AlertRecord).where(
        AlertRecord.group_key == group_key,
        AlertRecord.state.in_(["firing", "processing", "restored"])
    )
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    # ── resolved / Grafana 自动恢复 ────────────────────────────────────────────
    if status == "resolved" and existing:
        existing.state = "restored"
        existing.updated_at = datetime.utcnow()
        history = json.loads(existing.history or "[]")
        history.append({
            "time": datetime.utcnow().isoformat(),
            "event": "auto_restored",
            "note": "Grafana 自动恢复",
        })
        existing.history = json.dumps(history, ensure_ascii=False)
        await db.commit()

        if existing.lark_message_id:
            card = _build_card_from_record(existing, starts_at_str)
            try:
                await lark_client.update_card(existing.lark_message_id, card)
            except Exception as e:
                logger.warning(f"update_card failed: {e}")

        return {"code": 200, "results": [{"group_key": group_key, "action": "auto_restored"}]}

    # ── 重复 firing：更新数据并重发卡片 ────────────────────────────────────────
    if existing and status == "firing":
        logger.info(f"Duplicate firing, re-sending card: {group_key}")
        existing.starts_at = starts_at_dt
        existing.updated_at = datetime.utcnow()
        existing.alerts_json = json.dumps(alerts_json_data, ensure_ascii=False)
        await db.flush()

        card = _build_card_from_record(existing, starts_at_str)
        try:
            message_id = await lark_client.send_card(settings.ALERT_GROUP_ID, card)
            existing.lark_message_id = message_id
        except Exception as e:
            logger.error(f"re-send card failed: {e}")
        await db.commit()
        return {"code": 200, "results": [{"group_key": group_key, "action": "resent", "alert_id": existing.id}]}

    # ── 新建告警记录 ────────────────────────────────────────────────────────────
    record = AlertRecord(
        id=str(uuid.uuid4()),
        fingerprint=first.fingerprint,
        group_key=group_key,
        alertname=alertname,
        address=address,
        symbol=symbol,
        alert_type=alert_type,
        ptype=ptype,
        grafana_folder=grafana_folder,
        instance=instance,
        value_a=value_a,
        value_b=value_b,
        value_c=value_c,
        state="firing",
        starts_at=starts_at_dt,
        updated_at=datetime.utcnow(),
        history=json.dumps([{
            "time": datetime.utcnow().isoformat(),
            "event": "firing",
            "note": f"Grafana 告警触发，共 {len(payload.alerts)} 条",
        }], ensure_ascii=False),
        raw_labels=json.dumps(dict(common_labels), ensure_ascii=False),
        alerts_json=json.dumps(alerts_json_data, ensure_ascii=False),
        dashboard_url=first.dashboardURL,
        panel_url=first.panelURL,
        generator_url=first.generatorURL,
        silence_url=first.silenceURL,
    )
    db.add(record)
    await db.flush()

    card = _build_card_from_record(record, starts_at_str)
    try:
        message_id = await lark_client.send_card(settings.ALERT_GROUP_ID, card)
        record.lark_message_id = message_id
    except Exception as e:
        logger.error(f"send_card failed: {e}")

    await db.commit()
    logger.info(f"New alert created: {record.id} [{alertname}] ({len(payload.alerts)} alerts merged)")
    return {"code": 200, "results": [{"group_key": group_key, "action": "created", "alert_id": record.id}]}
