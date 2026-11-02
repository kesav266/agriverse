import time
from typing import Generator
from sqlalchemy import create_engine, text, inspect, event
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings
from app.core.logging import logger

db_url = settings.effective_database_url

# Configure database engine appropriately for SQLite vs PostgreSQL / Supabase
connect_args = {}
engine_kwargs = {"echo": False}

if db_url.startswith("sqlite"):
    connect_args["check_same_thread"] = False
    if db_url in {"sqlite://", "sqlite:///:memory:"}:
        engine_kwargs["poolclass"] = StaticPool
else:
    # PostgreSQL / Supabase pooling options
    engine_kwargs.update({
        "pool_pre_ping": True,
        "pool_recycle": 300,
    })

engine = create_engine(db_url, connect_args=connect_args, **engine_kwargs)

if engine.dialect.name == "sqlite":
    @event.listens_for(engine, "connect")
    def enable_sqlite_foreign_keys(connection, _record):
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db() -> Generator[Session, None, None]:
    """Dependency that provides a thread-safe database session to FastAPI routes."""
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

def check_db_connection() -> dict:
    """Verify database connectivity and measure response latency."""
    start_time = time.time()
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        latency_ms = round((time.time() - start_time) * 1000, 2)
        dialect = engine.dialect.name
        return {
            "status": "connected",
            "dialect": dialect,
            "latency_ms": latency_ms,
            "is_postgres": dialect == "postgresql"
        }
    except Exception:
        latency_ms = round((time.time() - start_time) * 1000, 2)
        logger.error("Database connectivity check failed")
        return {
            "status": "disconnected",
            "latency_ms": latency_ms,
            "dialect": engine.dialect.name
        }

def init_db():
    """Create only a local SQLite development schema; PostgreSQL uses reviewed SQL migrations."""
    if engine.dialect.name != "sqlite":
        return
    try:
        # Import domain models so metadata knows all tables
        import app.models.domain  # noqa: F401
        Base.metadata.create_all(bind=engine)
        columns = {column["name"] for column in inspect(engine).get_columns("yield_estimates")}
        with engine.begin() as connection:
            if "farmer_id" not in columns:
                connection.execute(text("ALTER TABLE yield_estimates ADD COLUMN farmer_id VARCHAR(36)"))
            if "crop_name" not in columns:
                connection.execute(text("ALTER TABLE yield_estimates ADD COLUMN crop_name VARCHAR(100)"))
        logger.info("Local SQLite development schema is ready")
    except Exception:
        logger.exception("Local SQLite schema initialization failed")
        raise
