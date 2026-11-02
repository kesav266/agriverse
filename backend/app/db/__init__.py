from .database import engine, SessionLocal, Base, get_db, check_db_connection, init_db

__all__ = [
    "engine",
    "SessionLocal",
    "Base",
    "get_db",
    "check_db_connection",
    "init_db",
    "ProfileRepository",
    "FarmRepository",
    "CropCycleRepository",
]


def __getattr__(name):
    if name in {"ProfileRepository", "FarmRepository", "CropCycleRepository"}:
        from . import repositories

        return getattr(repositories, name)
    raise AttributeError(name)
