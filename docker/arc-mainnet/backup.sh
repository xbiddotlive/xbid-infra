#!/bin/sh
set -eu
umask 077
cd /opt/xbid-arc/current/infra/docker/arc-mainnet
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir=/opt/xbid-arc/backups/$stamp
mkdir -m 700 "$backup_dir"
docker compose exec -T postgres pg_dump -U xbid_admin -d xbid -Fc > "$backup_dir/xbid.dump"
docker compose exec -T backend tar -C /app/var -czf - uploads > "$backup_dir/uploads.tar.gz"
docker compose exec -T postgres pg_restore --list < "$backup_dir/xbid.dump" > "$backup_dir/restore-list.txt"
printf 'XBID backup complete: %s\n' "$backup_dir"
# No automatic deletion: off-server retention policy must be configured explicitly.
