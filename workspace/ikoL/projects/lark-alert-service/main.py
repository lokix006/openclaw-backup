import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings
from app.database import init_db
from app.routers import webhook, callback, alerts

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    logger.info("Database initialized")
    yield


app = FastAPI(
    title="Lark Alert Service",
    description="Grafana → Lark 告警交互中间层服务",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(webhook.router, tags=["Grafana Webhook"])
app.include_router(callback.router, tags=["Lark Callback"])
app.include_router(alerts.router, prefix="/api", tags=["Alert Management"])


@app.get("/health")
async def health():
    return {"status": "ok"}
