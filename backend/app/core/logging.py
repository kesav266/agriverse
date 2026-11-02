import logging
import re
import sys


class ProviderSecretRedactionFilter(logging.Filter):
    """Redact credential query parameters from HTTP client request logs."""

    _secret_query = re.compile(
        r"(?i)([?&](?:appid|api[_-]?key|access[_-]?token|token)=)[^&\s\"']+"
    )

    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        record.msg = self._secret_query.sub(r"\1[REDACTED]", message)
        record.args = ()
        return True


def setup_logging():
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    redaction_filter = ProviderSecretRedactionFilter()
    for handler in logging.getLogger().handlers:
        handler.addFilter(redaction_filter)
    logger = logging.getLogger("agriverse_backend")
    logger.info("Structured logging initialized for AgriVerse AI Backend.")
    return logger

logger = setup_logging()
