from pathlib import Path
import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent

db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT", "3306")
db_name = os.getenv("DB_NAME")
custom_db_url = os.getenv("DATABASE_URL")


def build_engine():
    target_url = None
    connect_args = {}

    if custom_db_url:
        target_url = custom_db_url
        if target_url.startswith("postgres://"):
            target_url = target_url.replace("postgres://", "postgresql://", 1)
    elif db_host and db_user and db_name:
        password_part = f":{db_password}" if db_password else ""
        target_url = (
            f"mysql+pymysql://{db_user}{password_part}@{db_host}:{db_port}/{db_name}"
        )
        connect_args = {"connect_timeout": 3}

    if target_url:
        try:
            test_engine = create_engine(target_url, connect_args=connect_args)
            with test_engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print(f"[Database] Connected to external database successfully.")
            return test_engine
        except Exception as e:
            print(f"[Database] Warning: Remote DB connection failed ({e}). Falling back to SQLite.")

    sqlite_path = BASE_DIR / "uzhavanai.db"
    return create_engine(
        f"sqlite:///{sqlite_path.as_posix()}",
        connect_args={"check_same_thread": False},
    )


engine = build_engine()

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def _run_schema_creation(eng):
    is_sqlite = eng.dialect.name == "sqlite"
    pk_auto = (
        "INTEGER PRIMARY KEY AUTOINCREMENT"
        if is_sqlite
        else "INT AUTO_INCREMENT PRIMARY KEY"
    )

    with eng.begin() as conn:
        conn.execute(
            text(f"""
                CREATE TABLE IF NOT EXISTS farmers (
                    id {pk_auto},
                    name VARCHAR(255) NOT NULL,
                    phone VARCHAR(50) NOT NULL,
                    village VARCHAR(255) NOT NULL
                )
            """)
        )

        conn.execute(
            text(f"""
                CREATE TABLE IF NOT EXISTS predictions (
                    id {pk_auto},
                    crop VARCHAR(100),
                    disease VARCHAR(100),
                    class_name VARCHAR(255),
                    confidence REAL,
                    treatment TEXT,
                    prevention TEXT,
                    fertilizer TEXT,
                    image_name VARCHAR(255),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
        )

        conn.execute(
            text(f"""
                CREATE TABLE IF NOT EXISTS recovery_trackers (
                    id {pk_auto},
                    prediction_id INTEGER,
                    crop VARCHAR(100),
                    disease VARCHAR(100),
                    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status VARCHAR(50) DEFAULT 'Monitoring'
                )
            """)
        )

        conn.execute(
            text(f"""
                CREATE TABLE IF NOT EXISTS recovery_updates (
                    id {pk_auto},
                    tracker_id INTEGER,
                    image_name VARCHAR(255),
                    confidence REAL,
                    notes TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
        )


def init_db():
    global engine
    try:
        _run_schema_creation(engine)
    except Exception as e:
        print(f"[Database] Schema creation failed with current engine ({e}). Re-trying with SQLite.")
        sqlite_path = BASE_DIR / "uzhavanai.db"
        engine = create_engine(
            f"sqlite:///{sqlite_path.as_posix()}",
            connect_args={"check_same_thread": False},
        )
        _run_schema_creation(engine)