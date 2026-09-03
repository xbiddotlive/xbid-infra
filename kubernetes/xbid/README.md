# XBID Kubernetes deployment

XBID uses one DigitalOcean Kubernetes cluster with strict environment isolation:

| Environment | Namespace | Web | API | Database |
| --- | --- | --- | --- | --- |
| Testnet | `xbid-testnet` | `testnet.xbid.live` | `api-testnet.xbid.live` | dedicated single-instance CloudNativePG |
| Mainnet | `xbid-mainnet` | `xbid.live` | `api.xbid.live` | dedicated HA CloudNativePG |

The two environments never share secrets, databases, volumes, contract
addresses or indexer schemas. The mainnet overlay is intentionally stored as a
gated template until mainnet chain values and capacity are approved.

## Image release

The frontend, backend and indexer repositories each build a private GHCR image
from `main`. Testnet uses the `testnet` frontend tag and the `main` backend and
indexer tags. Production must pin all images to immutable commit SHAs.

Configure `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` as a GitHub Actions secret in
the frontend repository before publishing the Testnet frontend image.

Create a namespace-scoped GHCR pull secret without storing the token in Git:

```bash
kubectl create namespace xbid-testnet
kubectl create secret docker-registry ghcr \
  --namespace xbid-testnet \
  --docker-server=ghcr.io \
  --docker-username=<github-user> \
  --docker-password='<github-token-with-read-packages>'
```

## Testnet release

Before applying, point both Testnet DNS records at the existing NGINX ingress
load balancer and verify that the `wechart` ClusterIssuer is Ready.

Releases that change the projection schema are coordinated releases. Apply the
latest `xbid-database` migration first, deploy the indexer and wait for it to
finish replaying to the current confirmed block, then deploy the backend and
frontend. In particular, the balance, public-volume and trader-performance
projections must exist before the corresponding API image is started.

```bash
kubectl kustomize kubernetes/xbid/overlays/testnet
kubectl apply --dry-run=server -k kubernetes/xbid/overlays/testnet
kubectl apply -k kubernetes/xbid/overlays/testnet
kubectl rollout status deployment/xbid-backend -n xbid-testnet
kubectl rollout status deployment/xbid-indexer -n xbid-testnet
kubectl rollout status deployment/xbid-frontend -n xbid-testnet
```

After DNS propagation, verify both the primary `api-testnet.xbid.live` endpoint
and the legacy `api.testnet.xbid.live` endpoint. The legacy host remains routed
so immutable metadata URLs created before the hostname change continue to work.

## Production rules

- Never deploy the mainnet template with Testnet addresses.
- Use two or more application replicas and two PostgreSQL instances with pod
  anti-affinity.
- Add a dedicated node pool before Mainnet if cluster headroom is below 30%.
- Enable scheduled volume backups and an off-cluster logical backup.
- Run a restore drill before accepting users.
- Keep the indexer private; only the web and API ingresses are public.
- Uploaded logos use a retained PVC for Testnet. Move them to S3-compatible
  object storage before horizontally scaling the Mainnet API.
