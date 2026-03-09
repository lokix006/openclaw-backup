"""
模块1: 接收 Grafana Webhook → 解析 → 持久化 → 推送 Lark 卡片
"""
import json
import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
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


@router.post("/grafana-webhook")
async def grafana_webhook(payload: GrafanaWebhookPayload, db: AsyncSession = Depends(get_db)):
    """
    接收 Grafana Alertmanager Webhook，每个 alert 独立处理。
    - firing → 创建新记录并发送 Lark 卡片
    - resolved (Grafana 自动恢复) → 更新状态为 restored
    """
    results = []

    for alert in payload.alerts:
        labels = alert.labels
        alertname = labels.get("alertname", "Unknown Alert")
        address = labels.get("address")
        symbol = labels.get("symbol")
        alert_type = labels.get("type")
        ptype = labels.get("ptype")
        grafana_folder = labels.get("grafana_folder")
        instance = labels.get("instance")

        values = alert.values or {}
        value_a = values.get("A")
        value_b = values.get("B")
        value_c = values.get("C")

        starts_at_dt = _parse_starts_at(alert.startsAt)
        starts_at_str = starts_at_dt.strftime("%Y-%m-%d %H:%M:%S UTC")

        # 查是否已有相同 fingerprint 的活跃告警
        stmt = select(AlertRecord).where(
            AlertRecord.fingerprint == alert.fingerprint,
            AlertRecord.state.in_(["firing", "processing", "restored"])
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if alert.status == "resolved" and existing:
            # Grafana 自动恢复
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

            # 更新卡片
            if existing.lark_message_id:
                card = card_builder.build_alert_card(
                    alert_id=existing.id,
                    alertname=existing.alertname,
                    address=existing.address,
                    symbol=existing.symbol,
                    alert_type=existing.alert_type,
                    grafana_folder=existing.grafana_folder,
                    value_a=existing.value_a,
                    starts_at=starts_at_str,
                    state="restored",
                    handler_name=existing.handler_name,
                    dashboard_url=existing.dashboard_url,
                    silence_url=existing.silence_url,
                    generator_url=existing.generator_url,
                )
                try:
                    await lark_client.update_card(existing.lark_message_id, card)
                except Exception as e:
                    logger.warning(f"update_card failed: {e}")

            results.append({"fingerprint": alert.fingerprint, "action": "auto_restored"})
            continue

        if existing:
            # 重复 firing：允许重新发送卡片（用已有 record，更新 starts_at 和卡片）
            logger.info(f"Duplicate firing alert, re-sending card: {alert.fingerprint}")
            existing.starts_at = starts_at_dt
            existing.updated_at = datetime.utcnow()
            await db.flush()

            card = card_builder.build_alert_card(
                alert_id=existing.id,
                alertname=existing.alertname,
                address=existing.address,
                symbol=existing.symbol,
                alert_type=existing.alert_type,
                grafana_folder=existing.grafana_folder,
                value_a=existing.value_a,
                starts_at=starts_at_str,
                state=existing.state,
                handler_name=existing.handler_name,
                dashboard_url=existing.dashboard_url,
                silence_url=existing.silence_url,
                generator_url=existing.generator_url,
            )
            try:
                message_id = await lark_client.send_card(settings.ALERT_GROUP_ID, card)
                existing.lark_message_id = message_id
            except Exception as e:
                logger.error(f"re-send card failed: {e}")
            await db.commit()
            results.append({"fingerprint": alert.fingerprint, "action": "resent", "alert_id": existing.id})
            continue

        # 新建告警记录
        record = AlertRecord(
            id=str(uuid.uuid4()),
            fingerprint=alert.fingerprint,
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
                "note": "Grafana 告警触发",
            }], ensure_ascii=False),
            raw_labels=json.dumps(labels, ensure_ascii=False),
            dashboard_url=alert.dashboardURL,
            generator_url=alert.generatorURL,
            silence_url=alert.silenceURL,
            panel_url=alert.panelURL,
        )
        db.add(record)
        await db.flush()  # 获取 id

        # 构建并发送卡片
        card = card_builder.build_alert_card(
            alert_id=record.id,
            alertname=alertname,
            grafana_folder=grafana_folder,
            address=address,
            symbol=symbol,
            alert_type=alert_type,
            ptype=ptype,
            instance=instance,
            value_a=value_a,
            value_b=value_b,
            value_c=value_c,
            starts_at=starts_at_str,
            state="firing",
            dashboard_url=alert.dashboardURL,
            panel_url=alert.panelURL,
            silence_url=alert.silenceURL,
            generator_url=alert.generatorURL,
            extra_labels=labels,
        )

        try:
            message_id = await lark_client.send_card(settings.ALERT_GROUP_ID, card)
            record.lark_message_id = message_id
        except Exception as e:
            logger.error(f"send_card failed: {e}")

        await db.commit()
        results.append({"fingerprint": alert.fingerprint, "action": "created", "alert_id": record.id})
        logger.info(f"New alert created: {record.id} [{alertname}]")

    return {"code": 200, "results": results}
