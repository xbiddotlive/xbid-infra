// Run once in a Node container with /secrets mounted to /opt/xbid-arc/secrets.
// No credentials are printed or included in source/release archives.
import { randomBytes } from 'node:crypto';
import { existsSync, writeFileSync } from 'node:fs';
const names = ['database.env', 'backend.env', 'indexer.env'];
if (names.some(n => existsSync(`/secrets/${n}`))) throw new Error('Refusing to overwrite existing database credentials.');
const admin = randomBytes(32).toString('hex');
const api = randomBytes(32).toString('hex');
const indexer = randomBytes(32).toString('hex');
writeFileSync('/secrets/database.env', `POSTGRES_USER=xbid_admin\nPOSTGRES_DB=xbid\nPOSTGRES_PASSWORD=${admin}\nPOSTGRES_INITDB_ARGS=--auth-host=scram-sha-256\nXBID_API_PASSWORD=${api}\nXBID_INDEXER_PASSWORD=${indexer}\n`, { mode: 0o600, flag: 'wx' });
writeFileSync('/secrets/backend.env', `DATABASE_URL=postgresql://xbid:${api}@postgres:5432/xbid?sslmode=disable\n`, { mode: 0o600, flag: 'wx' });
writeFileSync('/secrets/indexer.env', `DATABASE_URL=postgresql://xbid_indexer:${indexer}@postgres:5432/xbid?sslmode=disable\n`, { mode: 0o600, flag: 'wx' });
console.log('Created three restricted credential files; values not displayed.');
