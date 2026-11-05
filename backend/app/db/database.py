import time
from typing import Generator
from sqlalchemy import create_engine, text, inspect, event
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings
from app.core.logging import logger

db_url = settings.effective_database_url

def _create_engine_for_url(target_url: str):
    connect_args = {}
    engine_kwargs = {"echo": False}
    if target_url.startswith("sqlite"):
        connect_args["check_same_thread"] = False
        if target_url in {"sqlite://", "sqlite:///:memory:"}:
            engine_kwargs["poolclass"] = StaticPool
    else:
        # PostgreSQL / Supabase pooling options
        engine_kwargs.update({
            "pool_pre_ping": True,
            "pool_recycle": 300,
        })
    eng = create_engine(target_url, connect_args=connect_args, **engine_kwargs)
    if eng.dialect.name == "sqlite":
        @event.listens_for(eng, "connect")
        def enable_sqlite_foreign_keys(connection, _record):
            cursor = connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()
    return eng

engine = _create_engine_for_url(db_url)
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

def _sync_sqlite_columns(eng):
    """Preserve compatibility with the two optional yield-history columns."""
    inspector = inspect(eng)
    table_name = "yield_estimates"
    if not inspector.has_table(table_name):
        return

    existing_cols = {column["name"] for column in inspector.get_columns(table_name)}
    legacy_columns = {"farmer_id": "VARCHAR(36)", "crop_name": "VARCHAR(100)"}
    with eng.begin() as connection:
        for column_name, column_type in legacy_columns.items():
            if column_name not in existing_cols:
                logger.info(
                    "Migrating SQLite schema: adding %s (%s) to %s",
                    column_name,
                    column_type,
                    table_name,
                )
                connection.execute(
                    text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type}")
                )

def init_db():
    """Initialize SQLite development storage or verify a migrated PostgreSQL schema."""
    global engine, SessionLocal
    try:
        # Import domain models so metadata knows all tables
        import app.models.domain  # noqa: F401
        if engine.dialect.name == "sqlite":
            Base.metadata.create_all(bind=engine)
            _sync_sqlite_columns(engine)
        else:
            # An explicit PostgreSQL configuration must fail visibly when unavailable;
            # silently switching databases could split reads and writes across stores.
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))

            required_tables = {
                "profiles",
                "farms",
                "crop_cycles",
                "farm_observations",
                "crop_recommendations",
                "weather_observations",
                "crop_health_diagnoses",
                "yield_estimates",
                "assistant_conversations",
                "assistant_messages",
            }
            existing_tables = set(inspect(engine).get_table_names(schema="public"))
            missing_tables = sorted(required_tables - existing_tables)
            if missing_tables:
                raise RuntimeError(
                    "PostgreSQL schema is incomplete. Apply the reviewed database migrations before starting "
                    f"the API. Missing tables: {', '.join(missing_tables)}"
                )
        logger.info("Database schema is ready; dialect=%s", engine.dialect.name)
    except Exception:
        logger.exception("Database schema initialization failed")
        raise
