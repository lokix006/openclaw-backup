"""
告警管理 API — 查询告警列表、手动更新状态（供 OpenClaw 归档调用）
"""
import json
import logging
from datetime import datetime
from typing import Optional, List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import AlertRecord
from app.database import get_db

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/alerts")
async def list_alerts(
    state: Optional[str] = Query(None, description="过滤状态: firing|processing|restored|resolved|ignored"),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(AlertRecord).order_by(AlertRecord.updated_at.desc()).limit(limit)
    if state:
        stmt = stmt.where(AlertRecord.state == state)
    result = await db.execute(stmt)
    records = result.scalars().all()
    return {"code": 200, "data": [_serialize(r) for r in records]}


@router.get("/alerts/{alert_id}")
async def get_alert(alert_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(AlertRecord).where(AlertRecord.id == alert_id)
    result = await db.execute(stmt)
    record = result.scalar_one_or_none()
    if not record:
        return {"code": 404, "msg": "not found"}
    return {"code": 200, "data": _serialize(record)}


@router.post("/alerts/{alert_id}/archive")
async def archive_alert(alert_id: str, body: dict, db: AsyncSession = Depends(get_db)):
    """由 OpenClaw Bot 调用，写入 LLM 归档总结"""
    stmt = select(AlertRecord).where(AlertRecord.id == alert_id)
    result = await db.execute(stmt)
    record = result.scalar_one_or_none()
    if not record:
        return {"code": 404, "msg": "not found"}
    record.summary = body.get("summary", "")
    record.updated_at = datetime.utcnow()
    await db.commit()
    return {"code": 200, "msg": "archived"}


def _serialize(r: AlertRecord) -> dict:
    return {
        "id": r.id,
        "fingerprint": r.fingerprint,
        "alertname": r.alertname,
        "address": r.address,
        "symbol": r.symbol,
        "type": r.alert_type,
        "grafana_folder": r.grafana_folder,
        "value_a": r.value_a,
        "state": r.state,
        "handler": r.handler_name,
        "starts_at": r.starts_at.isoformat() if r.starts_at else None,
        "updated_at": r.updated_at.isoformat() if r.updated_at else None,
        "resolved_at": r.resolved_at.isoformat() if r.resolved_at else None,
        "history": json.loads(r.history or "[]"),
        "summary": r.summary,
        "lark_message_id": r.lark_message_id,
        "dashboard_url": r.dashboard_url,
    }
