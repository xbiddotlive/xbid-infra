#!/bin/sh
set -eu
# Only used by PostgreSQL on a brand-new XBID data volume; never on an existing database.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set=api_password="$XBID_API_PASSWORD" --set=indexer_password="$XBID_INDEXER_PASSWORD" <<'SQL'
CREATE ROLE xbid LOGIN PASSWORD :'api_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
CREATE ROLE xbid_indexer LOGIN PASSWORD :'indexer_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE xbid TO xbid, xbid_indexer;
GRANT CREATE ON DATABASE xbid TO xbid_indexer;
CREATE SCHEMA app AUTHORIZATION xbid_admin;
CREATE SCHEMA chain_projection AUTHORIZATION xbid_indexer;
GRANT USAGE ON SCHEMA app, chain_projection TO xbid;
ALTER DEFAULT PRIVILEGES FOR ROLE xbid_indexer IN SCHEMA chain_projection GRANT SELECT ON TABLES TO xbid;
SQL
for migration in /migrations/*.sql; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$migration"
done
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO xbid;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO xbid;
ALTER DEFAULT PRIVILEGES FOR ROLE xbid_admin IN SCHEMA app GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO xbid;
ALTER DEFAULT PRIVILEGES FOR ROLE xbid_admin IN SCHEMA app GRANT USAGE, SELECT ON SEQUENCES TO xbid;
SQL
