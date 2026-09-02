# XBID local full-stack runtime

This repository owns local and deployment infrastructure. Application code is
kept in the dedicated frontend, backend, indexer, database, and contract
repositories.

## Current local topology

| Service | Address |
| --- | --- |
| Next.js frontend | `http://localhost:3000` |
| NestJS API | `http://localhost:4000` |
| Swagger | `http://localhost:4000/docs` |
| Ponder API | `http://localhost:42069` |
| PostgreSQL | `127.0.0.1:55432` |

PostgreSQL uses port `55432` locally so it does not overwrite or collide with a
developer's existing PostgreSQL server on `5432`.

## Startup order

1. Start PostgreSQL with `docker compose -f docker/compose.local.yml up -d`.
2. Start `xbid-indexer` with `pnpm dev`.
3. Start `xbid-backend` with `pnpm dev`.
4. Start `xbid-frontend` with `pnpm dev`.
5. Verify API readiness at `/v1/health` before browser E2E testing.

Copy each repository's `.env.example` to its ignored local environment file.
Never commit private keys, Safe signer material, or production RPC credentials.
