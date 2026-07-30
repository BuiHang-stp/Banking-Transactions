# config.py — Cấu hình kết nối Postgres
import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import URL, create_engine

# Thư mục gốc dự án = thư mục cha của src/
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")
PG_HOST = os.getenv("PG_HOST", "localhost")
PG_PORT = os.getenv("PG_PORT", "5432")
PG_DB   = os.getenv("PG_DB", "bank_transactions")
PG_USER = os.getenv("PG_USER", "postgres")
PG_PASS = os.getenv("PG_PASSWORD", "")
RAW_XLSX = PROJECT_ROOT / os.getenv("RAW_XLSX", "data/raw/Banking_Transactional_Dataset.xlsx")
RAW_SHEET = os.getenv("RAW_SHEET", "Banking Data")
def get_engine():
    """Trả về SQLAlchemy engine nối tới Postgres."""
    if not PG_PASS:
        raise RuntimeError(
            "Chưa có PG_PASSWORD. Tạo file .env ở thư mục gốc dự án")
    url = URL.create(
        drivername="postgresql+psycopg2", username=PG_USER, password=PG_PASS,
        host=PG_HOST, port=int(PG_PORT), database=PG_DB,)
    return create_engine(url)