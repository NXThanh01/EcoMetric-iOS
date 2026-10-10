from functools import lru_cache

from typing import Literal, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import URL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="ECOMETRIC_",
        extra="ignore",
    )

    db_host: str = "127.0.0.1"
    db_port: int = Field(default=5432, ge=1, le=65_535)
    db_name: str = "ecometric_dev"
    db_user: str = "ecometric_app"
    db_password: str
    gemini_api_key: Optional[str] = None
    gemini_model: str = "gemini-3.8-flash"
    gemini_fallback_model: Optional[str] = "gemini-3.5-flash"
    email_delivery_mode: Literal["console", "smtp"] = "console"
    smtp_host: Optional[str] = None
    smtp_port: int = Field(default=587, ge=1, le=65_535)
    smtp_username: Optional[str] = None
    smtp_password: Optional[str] = None
    smtp_from_email: Optional[str] = None
    smtp_use_tls: bool = True
    smtp_use_ssl: bool = False
    otp_secret: Optional[str] = None

    @property
    def effective_otp_secret(self) -> str:
        return self.otp_secret or self.db_password

    @property
    def database_url(self) -> URL:
        return URL.create(
            drivername="postgresql+psycopg",
            username=self.db_user,
            password=self.db_password,
            host=self.db_host,
            port=self.db_port,
            database=self.db_name,
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
