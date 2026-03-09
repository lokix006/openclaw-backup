import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    LARK_APP_ID: str = os.getenv("LARK_APP_ID", "")
    LARK_APP_SECRET: str = os.getenv("LARK_APP_SECRET", "")
    ALERT_GROUP_ID: str = os.getenv("ALERT_GROUP_ID", "")
    LARK_VERIFICATION_TOKEN: str = os.getenv("LARK_VERIFICATION_TOKEN", "")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./data/alerts.db")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


settings = Settings()
