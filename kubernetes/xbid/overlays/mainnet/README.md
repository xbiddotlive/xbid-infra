# XBID mainnet release gate

This overlay is intentionally non-deployable until the mainnet contracts and
capacity review are complete. Copy each `*.example` file to the same name
without `.example`, replace every `REQUIRED_*` value, then run the checks in the
parent deployment guide.

Mainnet prerequisites:

1. Mainnet chain ID, RPC, explorer, contract addresses, deployment start block,
   reference contest and WalletConnect project ID are approved.
2. A dedicated node pool has enough headroom for two web/API replicas, one
   indexer and two PostgreSQL instances on distinct nodes.
3. `xbid.live` and `api.xbid.live` point to the ingress load balancer.
4. Database backup and restore drills have passed.
5. The image tags are immutable commit SHAs, never `latest` or `main`.
6. Contract activation follows the Safe and Timelock release procedure.

Do not use Testnet addresses or the Testnet database in this environment.
