import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, Text
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class AlertRecord(Base):
    __tablename__ = "alert_records"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    fingerprint = Column(String, index=True)          # Grafana fingerprint (唯一标识)
    alertname = Column(String)
    address = Column(String, nullable=True)
    symbol = Column(String, nullable=True)
    alert_type = Column(String, nullable=True)        # type 字段（balance等）
    ptype = Column(String, nullable=True)             # ptype 字段（业务类型）
    grafana_folder = Column(String, nullable=True)
    instance = Column(String, nullable=True)
    value_a = Column(Float, nullable=True)
    value_b = Column(Float, nullable=True)
    value_c = Column(Float, nullable=True)
    raw_labels = Column(Text, default="{}")           # 完整 labels JSON，用于动态展示
    state = Column(String, default="firing")          # firing|processing|restored|resolved|ignored
    lark_message_id = Column(String, nullable=True)  # 卡片消息ID（用于更新）
    handler = Column(String, nullable=True)          # 接管人 open_id
    handler_name = Column(String, nullable=True)
    starts_at = Column(DateTime)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    history = Column(Text, default="[]")             # JSON list of state change logs
    summary = Column(Text, nullable=True)            # LLM归档总结
    dashboard_url = Column(String, nullable=True)
    panel_url = Column(String, nullable=True)
    generator_url = Column(String, nullable=True)
    silence_url = Column(String, nullable=True)
