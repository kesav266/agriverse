# Database operations

PostgreSQL/Supabase schema and SQL migrations for AgriVerse AI. The API uses its private backend database connection; the Flutter application never connects directly to PostgreSQL and never receives database credentials.

## Schema and ownership

The schema contains profiles, farms, crop cycles, observations, crop recommendations, weather observations, crop diagnoses, yield estimates, assistant conversations, and messages. User-facing API operations enforce ownership with the authenticated backend farmer ID. Supabase Data API policies separately scope rows to `profiles.supabase_auth_id` and an admin role. Backend custom-password accounts do not have a Supabase Auth UUID; they use the private backend connection.

Migration 009 removes the old policy behavior that treated NULL Supabase auth IDs as accessible, adds nullable `farmer_id` and `crop_name` to yield estimates, backfills only relationships that prove ownership, and sets compatibility views to `security_invoker`. Migration 010 adds `farm_observations.updated_at` and its update trigger. Historical yield rows with no provable owner remain stored but are not shown in farmer-scoped history. Neither migration deletes or resets user data.

## Applying changes

1. Take a database backup and verify a restore procedure before changing production.
2. On a fresh PostgreSQL 15+ database, apply numbered files `001` through `010` in order from `migrations/`.
3. If migrations `001` through `009` are already applied, review and apply only `migrations/010_farm_observation_updated_at.sql`. If only `001` through `008` are applied, review/apply `009_private_data_policies_and_estimate_ownership.sql`, then apply migration 010.
4. Verify policy behavior and backend ownership checks in staging, using two distinct farmer accounts.

Apply SQL in Supabase Dashboard SQL Editor or with an approved PostgreSQL client. This repository has no migration runner/history table; record the applied version in the deployment's change log. No migrations have been applied to a live database from this workspace. Before production changes, take and validate a custom-format `pg_dump` backup, restore it into isolated staging, apply only pending numbered migrations there, verify row counts/FKs/indexes/RLS with two farmer identities, and confirm observation `updated_at` changes. Keep the backup and rollback/restore procedure available during deployment. Example PowerShell commands: `pg_dump --dbname=$env:AGRIVERSE_DATABASE_URL --format=custom --file=$env:AGRIVERSE_BACKUP_FILE` and `pg_restore --list $env:AGRIVERSE_BACKUP_FILE`. Supply the variables via protected configuration; never put credentials in a command file or repository.

`schema.sql` is a cumulative schema for a fresh install only. If using it, run the combined `rls_policies.sql` after it; that file combines the secured RLS setup and additive ownership hardening. Do not combine the cumulative schema path with numbered migrations, and do not run `rls_policies.sql` as an additional step after numbered migrations.

`seed_data.sql` contains demonstration records for local development only. Never execute it against a production database. There is no production reset script.

## Important checks

- `yield_estimates.farmer_id` should be populated for all new backend estimates. Old unlinked rows can remain NULL when ownership cannot be proven.
- Supabase policies use the `auth.uid()` mapping. Verify no policy allows `supabase_auth_id IS NULL` as an owner.
- Compatibility views must use PostgreSQL 15+ `security_invoker=true` so table RLS remains effective.
- Backend connection strings and Supabase service-role keys are secrets. Keep them in the backend host's secret store and out of SQL/docs/mobile builds.
- Back up before production schema changes and preserve the backup for the deployment's retention period.
