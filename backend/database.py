from pathlib import Path
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent

# Check if MySQL environment variables are provided
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT", "3306")
db_name = os.getenv("DB_NAME")
custom_db_url = os.getenv("DATABASE_URL")

if custom_db_url:
    DATABASE_URL = custom_db_url
    connect_args = {}
elif db_host and db_user and db_name:
    password_part = f":{db_password}" if db_password else ""
    DATABASE_URL = (
        f"mysql+pymysql://{db_user}{password_part}@{db_host}:{db_port}/{db_name}"
    )
    connect_args = {}
else:
    # Gracefully default to local SQLite database so app works offline without MySQL
    sqlite_path = BASE_DIR / "uzhavanai.db"
    DATABASE_URL = f"sqlite:///{sqlite_path.as_posix()}"
    connect_args = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def init_db():
    """Create all required tables if they don't already exist."""
    is_sqlite = engine.dialect.name == "sqlite"
    pk_auto = (
        "INTEGER PRIMARY KEY AUTOINCREMENT"
        if is_sqlite
        else "INT AUTO_INCREMENT PRIMARY KEY"
    )

    with engine.begin() as conn:
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