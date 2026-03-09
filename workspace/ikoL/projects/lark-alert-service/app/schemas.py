from pydantic import BaseModel
from typing import Optional, Dict, Any, List


# ── Grafana Webhook 入参 ──────────────────────────────────────────────────────

class GrafanaAlert(BaseModel):
    fingerprint: str
    status: str                         # firing / resolved
    startsAt: str
    endsAt: Optional[str] = None
    labels: Dict[str, str] = {}
    annotations: Dict[str, Any] = {}
    values: Optional[Dict[str, Any]] = {}
    valueString: Optional[str] = None
    dashboardURL: Optional[str] = None
    generatorURL: Optional[str] = None
    panelURL: Optional[str] = None
    silenceURL: Optional[str] = None
    valueString: Optional[str] = None


class GrafanaWebhookPayload(BaseModel):
    version: Optional[str] = None
    orgId: Optional[int] = None
    status: str                         # firing / resolved
    title: Optional[str] = None
    state: Optional[str] = None
    message: Optional[str] = None
    receiver: Optional[str] = None
    alerts: List[GrafanaAlert] = []
    commonLabels: Dict[str, str] = {}
    commonAnnotations: Dict[str, Any] = {}
    groupLabels: Dict[str, str] = {}
    groupKey: Optional[str] = None
    externalURL: Optional[str] = None
    truncatedAlerts: Optional[int] = 0


# ── Lark 回调入参 ──────────────────────────────────────────────────────────────

class LarkCallbackHeader(BaseModel):
    event_type: Optional[str] = None


class LarkCardAction(BaseModel):
    open_id: Optional[str] = None
    name: Optional[str] = None
    action_value: Optional[str] = None  # 按钮 value: processing | resolved | ignored
    alert_id: Optional[str] = None


class LarkCallbackPayload(BaseModel):
    schema_: Optional[str] = None
    header: Optional[Dict[str, Any]] = None
    event: Optional[Dict[str, Any]] = None
    # URL验证
    challenge: Optional[str] = None
    token: Optional[str] = None
    type: Optional[str] = None
