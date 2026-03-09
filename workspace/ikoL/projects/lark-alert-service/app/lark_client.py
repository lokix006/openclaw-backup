"""
Lark API 客户端 — 封装 tenant_access_token 获取、消息发送与更新
"""
import httpx
import logging
from datetime import datetime, timedelta
from app.config import settings

logger = logging.getLogger(__name__)

_token_cache = {"token": None, "expires_at": datetime.min}

LARK_API = "https://open.larksuite.com/open-apis"


async def get_tenant_token() -> str:
    """获取/缓存 tenant_access_token"""
    global _token_cache
    if _token_cache["token"] and datetime.utcnow() < _token_cache["expires_at"]:
        return _token_cache["token"]

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{LARK_API}/auth/v3/tenant_access_token/internal",
            json={
                "app_id": settings.LARK_APP_ID,
                "app_secret": settings.LARK_APP_SECRET,
            },
        )
        data = resp.json()

    if data.get("code") != 0:
        raise RuntimeError(f"Lark token error: {data}")

    _token_cache["token"] = data["tenant_access_token"]
    _token_cache["expires_at"] = datetime.utcnow() + timedelta(seconds=data.get("expire", 7200) - 60)
    return _token_cache["token"]


async def send_card(group_id: str, card: dict) -> str:
    """发送交互卡片，返回 message_id"""
    token = await get_tenant_token()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{LARK_API}/im/v1/messages?receive_id_type=chat_id",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "receive_id": group_id,
                "msg_type": "interactive",
                "content": __import__("json").dumps(card),
            },
        )
        data = resp.json()

    if data.get("code") != 0:
        logger.error(f"Lark send_card error: {data}")
        raise RuntimeError(f"Lark send_card error: {data}")

    return data["data"]["message_id"]


async def update_card(message_id: str, card: dict):
    """更新已发送的交互卡片 — PATCH /im/v1/messages/{id}/content"""
    import json as _json
    token = await get_tenant_token()
    async with httpx.AsyncClient() as client:
        resp = await client.patch(
            f"{LARK_API}/im/v1/messages/{message_id}/content",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "content": _json.dumps(card, ensure_ascii=False),
            },
        )
        data = resp.json()
        logger.info(f"update_card response: code={data.get('code')} msg={data.get('msg')}")

    if data.get("code") != 0:
        logger.error(f"Lark update_card error: {data}")
        raise RuntimeError(f"Lark update_card error: {data}")
