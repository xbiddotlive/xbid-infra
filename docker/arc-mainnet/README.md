# XBID Arc mainnet / single-server release

Only for the authorized new server `69.55.59.184`. No old Kubernetes resources.
Contracts initially activated on Arc 5042 at block 23214351. V4 became the Factory
default at block 23230260, with a 15,000 USDC crown activation reserve. Existing
contests keep their original immutable version and threshold.

Layout: `/opt/xbid-arc/releases/<release>/{frontend,backend,indexer,database,infra}`.
Build contexts must be `git archive` exports of the exact pushed commits in the image tags.
Do not copy local environment files, testnet databases, wallet keys, or git credentials.
`/opt/xbid-arc/current` points to the accepted release; secrets and backups sit outside releases.

1. Export/push sources, copy release, then generate credentials once with the supplied Node script
   (bind secret directory to `/secrets`; never print values). Keep that directory mode 0700.
2. `docker compose config --quiet`; build Linux/amd64 images off the production host.
   The 4GB host must not run an unrestricted build alongside live services. Compose
   service `mem_limit` settings do not limit BuildKit or Next.js compilation.
   Use a dedicated local/CI BuildKit worker with a 3GB memory limit, a 2-CPU quota,
   and `max-parallelism = 1`; export the exact pushed commit and pass the public
   mainnet build arguments from this Compose file. Transfer/load the resulting image,
   verify its architecture and tag, then deploy with `--no-build`.
3. `docker compose up -d postgres indexer backend frontend`. No database/API/indexer public ports.
4. Check `http://127.0.0.1:3100/api/backend/v1/health`, empty mainnet discovery and indexer sync.
5. Verify the root DNS record points at this server; start `docker compose --profile public up -d caddy`.
   Caddy obtains a public certificate. Cloudflare must use Full (strict); never downgrade TLS.
   Only `xbid.live` is served. Existing testnet, indexer, email and other domains are untouched.
6. Verify HTTPS, Arc wallet chain, addresses and empty mainnet state. Real wallet transactions
   still require user signing and a separately approved creation/trading amount.
7. Install the two `xbid-arc-backup.*` units, take a backup and restore into an isolated check database.
   Local backups are not disaster protection from losing the server: encrypted off-site copies remain required.

The API uses restricted role `xbid` (app writes, projection reads); Ponder uses `xbid_indexer`
(owns projection/sync schema, no app access). No shared superuser login for applications.
Credentials use the isolated Docker network and are not bound to any host database port.

WalletConnect is not configured without an approved project ID; injected browser wallets remain available.
The frontend clears the historical default testnet contest. No fabricated volume, balances, trades or metadata.

Rollback: point `current` at the previous accepted release and `docker compose up -d --no-build` with
its recorded image IDs. Do not roll back by dropping data volumes. First production launch has no earlier
application release: turn off only this project's public Caddy service if acceptance fails.

Image cleanup: identify XBID image tags and inspect references from **all** containers,
including stopped containers. Retain the running, pending-release and previous accepted
rollback images. Remove only explicitly identified obsolete XBID image tags without
`--force`. Never use global `docker system prune`, volume pruning, or cleanup of other
projects. A dedicated XBID build worker's disposable cache may be pruned after its final
image has been loaded and verified. Image cleanup frees disk, not live process memory.
