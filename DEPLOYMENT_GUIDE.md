# AgriVerse AI Deployment Guide

This guide covers local development and the production deployment boundary. This checkout has no production API host, database project, release signing key, or hosting credentials, so it is not a production release.

## Local development

1. Install Python 3.11+, Flutter, Android Studio/Android SDK (for Android builds), and Java 17.
2. In PowerShell, install the backend and create a private local configuration:

   ```powershell
   cd backend
   py -3.11 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   Copy-Item .env.example .env
   ```

   Set a local `SECRET_KEY`; use PostgreSQL only when a disposable or development database is available. Empty `DATABASE_URL` selects local SQLite. Do not commit `.env`.

3. Start the API from `backend/` so the local SQLite file is created there:

   ```powershell
   .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
   ```

   Readiness: `http://127.0.0.1:8000/health/ready`; API docs: `http://127.0.0.1:8000/api/v1/docs`.

4. In another terminal, run the Flutter client:

   ```powershell
   cd frontend
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
   ```

   Use `http://10.0.2.2:8000/api/v1` for an Android emulator. For web, use the host-reachable API URL.

## PostgreSQL/Supabase

- Use a dedicated PostgreSQL project and a backend-only connection string. The Flutter app never connects to PostgreSQL or receives service-role keys.
- Back up and rehearse restore before schema changes. On a fresh database, apply `database/migrations/001` through `010` in order. For an existing database, apply only migrations newer than its recorded state. There is no migration runner in this repository; record applied versions in the deployment change log.
- Run `database/seed_data.sql` only in a disposable development environment.
- Verify row ownership, foreign keys, RLS, and compatibility views in staging using at least two farmer identities before production.
- Production settings require `ENVIRONMENT=production`, a private `SECRET_KEY` of at least 32 bytes, PostgreSQL `DATABASE_URL`, exact HTTPS `CORS_ORIGINS`, exact `TRUSTED_HOSTS`, and `HEALTHCHECK_HOST` included in `TRUSTED_HOSTS`.

## Disease model artifact

Model files are deliberately excluded from Git and the backend container image. Store reviewed weights in private artifact storage or a protected mounted volume. Set `DISEASE_MODEL_PATH` to the mounted path and `DISEASE_ALLOWED_LABELS` to a JSON array copied from that model's actual class metadata. The backend reads its `.env` from the backend directory regardless of process working directory and anchors relative model paths there.

Before enabling diagnosis, verify model provenance, dataset usage rights, exact labels, holdout metrics, uncertainty thresholds, image upload limits, and inference behavior on independent known images. `/health/ready` reports that a path and labels are configured; startup logs report whether model loading succeeded. It does not certify accuracy. The current local candidate and dataset remain machine-local and are not production-approved; see `AI_MODEL_REPORT.md`.

## Backend host and container

- Install `backend/requirements.txt` in the host runtime and run `uvicorn app.main:app --host 0.0.0.0 --port $PORT` behind an HTTPS reverse proxy or managed load balancer.
- The provided `backend/Dockerfile` runs as a non-root user and probes `/health/ready`. Inject production variables with the host secret manager; never copy local `.env` files or model weights into the image.
- The provided compose file binds the service to `127.0.0.1:8000`; terminate TLS at the reverse proxy. Restrict database ingress to the backend and use edge rate limits, request-size limits, monitoring, encrypted backups, and a restore rehearsal.
- Configure the edge to preserve the original host only when it is in `TRUSTED_HOSTS`; configure exact CORS web origins. Native Android clients do not use browser CORS.

## Web release

```powershell
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Replace the example URL with the deployed HTTPS API and publish `frontend/build/web` to an HTTPS static host/CDN. Never embed backend credentials in Flutter build defines.

## Android release

- Set the stable application ID and version in the Android Gradle configuration.
- Create and back up a release keystore outside the repository. Supply `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` through protected build secrets.
- Build only with the production HTTPS API URL:

  ```powershell
  cd frontend
  flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
  ```

- A build without the protected signing values is unsigned and cannot be published as a store release. Confirm application ID, permissions, privacy policy, store listing, signing, and tested API connectivity before distribution.

## Release gate

Do not call the deployment production-ready until staging migrations and restore have been verified, provider credentials have passed live checks, the reviewed model artifact is mounted and evaluated, HTTPS/CORS/host checks pass, Flutter web and signed Android artifacts are verified, and monitoring/backups/incident contacts are configured. Current blockers are summarized in `PROJECT_COMPLETION_REPORT.md`.
