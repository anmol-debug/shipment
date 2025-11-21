from pydantic_settings import BaseSettings
from typing import List
from dotenv import load_dotenv
import os

# Load environment variables before creating Settings
load_dotenv()


class Settings(BaseSettings):
    # Anthropic API Key
    ANTHROPIC_API_KEY: str = ""

    # Supabase Configuration
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    # Document types
    ALLOWED_DOCUMENT_TYPES: List[str] = [".pdf", ".xlsx", ".xls"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()
