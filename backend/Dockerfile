FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN addgroup --system app && adduser --system --ingroup app app

# Use production requirements (lighter, no YOLO) when available; fall back to full.
COPY requirements*.txt ./
RUN python -m pip install --upgrade pip && \
    if [ -f requirements.prod.txt ]; then \
        python -m pip install -r requirements.prod.txt; \
    else \
        python -m pip install -r requirements.txt; \
    fi

COPY --chown=app:app app ./app

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import os; from urllib.request import Request, urlopen; request = Request('http://127.0.0.1:8000/health/ready', headers={'Host': os.environ['HEALTHCHECK_HOST']}); urlopen(request, timeout=3)"

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers ${WEB_CONCURRENCY:-2}"]
